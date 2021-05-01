//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2020 stevapple and the SwiftTencentSCFRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//
//
// This source file was part of the SwiftAWSLambdaRuntime open source project
//
// Copyright (c) 2017-2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Logging
import NIO
import NIOConcurrencyHelpers

extension SCF {
    /// `Lifecycle` manages the SCF process lifecycle.
    ///
    /// - Note: It is intended to be used within a single `EventLoop`. For this reason this class is not thread safe.
    public final class Lifecycle {
        private let eventLoop: EventLoop
        private let shutdownPromise: EventLoopPromise<Int>
        private let logger: Logger
        private let configuration: Configuration
        private let factory: HandlerFactory

        private var state = State.idle {
            willSet {
                self.eventLoop.assertInEventLoop()
                precondition(newValue.order > self.state.order, "invalid state \(newValue) after \(self.state.order)")
            }
        }

        /// Create a new `Lifecycle`.
        ///
        /// - Parameters:
        ///     - eventLoop: An `EventLoop` to run the cloud function on.
        ///     - logger: A `Logger` to log the SCF events.
        ///     - factory: A `SCFHandlerFactory` to create the concrete SCF handler.
        public convenience init(eventLoop: EventLoop, logger: Logger, factory: @escaping HandlerFactory) {
            self.init(eventLoop: eventLoop, logger: logger, configuration: .init(), factory: factory)
        }

        init(eventLoop: EventLoop, logger: Logger, configuration: Configuration, factory: @escaping HandlerFactory) {
            self.eventLoop = eventLoop
            self.shutdownPromise = eventLoop.makePromise(of: Int.self)
            self.logger = logger
            self.configuration = configuration
            self.factory = factory
        }

        deinit {
            guard case .shutdown = self.state else {
                preconditionFailure("invalid state \(self.state)")
            }
        }

        /// The `Lifecycle` shutdown future.
        ///
        /// - Returns: An `EventLoopFuture` that is fulfilled after the SCF lifecycle has fully shutdown.
        public var shutdownFuture: EventLoopFuture<Int> {
            self.shutdownPromise.futureResult
        }

        /// Start the `Lifecycle`.
        ///
        /// - Returns: An `EventLoopFuture` that is fulfilled after the SCF hander has been created and initiliazed, and a first run has been scheduled.
        ///
        /// - Note: This method must be called  on the `EventLoop` the `Lifecycle` has been initialized with.
        public func start() -> EventLoopFuture<Void> {
            self.eventLoop.assertInEventLoop()

            logger.info("scf lifecycle starting with \(self.configuration)")
            self.state = .initializing

            var logger = self.logger
            logger[metadataKey: "lifecycleId"] = .string(self.configuration.lifecycle.id)
            let runner = Runner(eventLoop: self.eventLoop, configuration: self.configuration)

            let startupFuture = runner.initialize(logger: logger, factory: self.factory)
            startupFuture.flatMap { handler -> EventLoopFuture<(ByteBufferSCFHandler, Result<Int, Error>)> in
                // After the startup future has succeeded, we have a handler that we can use to
                // `run` the cloud function.
                let finishedPromise = self.eventLoop.makePromise(of: Int.self)
                self.state = .active(runner, handler)
                self.run(promise: finishedPromise)
                return finishedPromise.futureResult.mapResult { (handler, $0) }
            }
            .flatMap { handler, runnerResult -> EventLoopFuture<Int> in
                // After the SCF finishPromise has succeeded or failed we need to shutdown
                // the handler.
                let shutdownContext = ShutdownContext(logger: logger, eventLoop: self.eventLoop)
                return handler.shutdown(context: shutdownContext).flatMapErrorThrowing { error in
                    // If we had an error shuting down the SCF function, we want to concatenate
                    // it with the runner result.
                    logger.error("Error shutting down handler: \(error)")
                    throw RuntimeError.shutdownError(shutdownError: error, runnerResult: runnerResult)
                }.flatMapResult { _ -> Result<Int, Error> in
                    // We had no error shutting down the cloud function, so let's return the
                    // runner's result.
                    runnerResult
                }
            }.always { _ in
                // Triggered when the cloud function has finished its last run or has a startup failure.
                self.markShutdown()
            }.cascade(to: self.shutdownPromise)

            return startupFuture.map { _ in }
        }

        // MARK: -  Private

        #if DEBUG
        /// Begin the `Lifecycle` shutdown. Only needed for debugging purposes, hence behind a `DEBUG` flag.
        public func shutdown() {
            // Make this method thread safe by dispatching onto the eventLoop.
            self.eventLoop.execute {
                let oldState = self.state
                self.state = .shuttingdown
                if case .active(let runner, _) = oldState {
                    runner.cancelWaitingForNextInvocation()
                }
            }
        }
        #endif

        private func markShutdown() {
            self.state = .shutdown
        }

        @inline(__always)
        private func run(promise: EventLoopPromise<Int>) {
            func _run(_ count: Int) {
                switch self.state {
                case .active(let runner, let handler):
                    if self.configuration.lifecycle.maxTimes > 0, count >= self.configuration.lifecycle.maxTimes {
                        return promise.succeed(count)
                    }
                    var logger = self.logger
                    logger[metadataKey: "lifecycleIteration"] = "\(count)"
                    runner.run(logger: logger, handler: handler).whenComplete { result in
                        switch result {
                        case .success:
                            logger.log(level: .debug, "scf invocation sequence completed successfully")
                            // Recursive! According to the Tencent SCF Custom Runtime spec, the
                            // polling requests are to be done one at a time.
                            _run(count + 1)
                        case .failure(HTTPClient.Errors.cancelled):
                            if case .shuttingdown = self.state {
                                // If we are shutting down, we expect that the `getNextInvocation`
                                // request might have been cancelled.  For this reason we succeed
                                // the promise here.
                                logger.log(level: .info, "scf invocation sequence has been cancelled for shutdown")
                                return promise.succeed(count)
                            }
                            logger.log(level: .error, "scf invocation sequence has been cancelled unexpectedly")
                            promise.fail(HTTPClient.Errors.cancelled)
                        case .failure(let error):
                            logger.log(level: .error, "scf invocation sequence completed with error: \(error)")
                            promise.fail(error)
                        }
                    }
                case .shuttingdown:
                    promise.succeed(count)
                default:
                    preconditionFailure("invalid run state: \(self.state)")
                }
            }

            _run(0)
        }

        private enum State {
            case idle
            case initializing
            case active(Runner, Handler)
            case shuttingdown
            case shutdown

            internal var order: Int {
                switch self {
                case .idle:
                    return 0
                case .initializing:
                    return 1
                case .active:
                    return 2
                case .shuttingdown:
                    return 3
                case .shutdown:
                    return 4
                }
            }
        }
    }
}
