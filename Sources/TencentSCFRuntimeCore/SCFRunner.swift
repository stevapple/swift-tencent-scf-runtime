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
// Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Dispatch
import Logging
import NIO

extension SCF {
    /// `SCF.Runner` manages the SCF runtime workflow, or business logic.
    internal final class Runner {
        private let runtimeClient: RuntimeClient
        private let eventLoop: EventLoop
        private let allocator: ByteBufferAllocator

        private var isGettingNextInvocation = false

        init(eventLoop: EventLoop, configuration: Configuration) {
            self.eventLoop = eventLoop
            self.runtimeClient = RuntimeClient(eventLoop: self.eventLoop, configuration: configuration.runtimeEngine)
            self.allocator = ByteBufferAllocator()
        }

        /// Run the user provided initializer. This *must* only be called once.
        ///
        /// - Returns: An `EventLoopFuture<SCFHandler>` fulfilled with the outcome of the initialization.
        func initialize(logger: Logger, factory: @escaping HandlerFactory) -> EventLoopFuture<Handler> {
            logger.debug("initializing cloud function")
            // 1. Create the handler from the factory;
            // 2. Report initialization error if one occured.
            let context = InitializationContext(logger: logger,
                                                eventLoop: self.eventLoop,
                                                allocator: self.allocator)
            return factory(context)
                // Hopping back to "our" EventLoop is importnant in case the factory returns a future
                // that originated from a foreign EventLoop/EventLoopGroup.
                // This can happen if the factory uses a library (let's say a database client) that
                // manages its own threads/loops for whatever reason and returns a future that
                // originated from that foreign EventLoop.
                .hop(to: self.eventLoop)
                .flatMap { handler in
                    self.runtimeClient.reportInitializationReady(logger: logger)
                        .mapResult { _ in handler }
                }
                .peekError { error in
                    self.runtimeClient.reportInitializationError(logger: logger, error: error).peekError { reportingError in
                        // We're going to bail out because the init failed, so there's not a lot we
                        // can do other than log that we couldn't report this error back to the runtime.
                        logger.error("failed reporting initialization error to scf runtime engine: \(reportingError)")
                    }
                }
        }

        func run(logger: Logger, handler: Handler) -> EventLoopFuture<Void> {
            logger.debug("scf invocation sequence starting")
            // 1. Request invocation from the SCF Runtime Engine;
            self.isGettingNextInvocation = true
            return self.runtimeClient.getNextInvocation(logger: logger).peekError { error in
                logger.error("could not fetch work from scf runtime engine: \(error)")
            }.flatMap { invocation, event in
                // 2. Send invocation to the handler;
                self.isGettingNextInvocation = false
                let context = Context(logger: logger,
                                      eventLoop: self.eventLoop,
                                      allocator: self.allocator,
                                      invocation: invocation)
                logger.debug("sending invocation to scf handler \(handler)")
                return handler.handle(context: context, event: event)
                    // Hopping back to "our" EventLoop is importnant in case the factory returns a future
                    // that originated from a foreign EventLoop/EventLoopGroup.
                    // This can happen if the factory uses a library (let's say a database client) that
                    // manages its own threads/loops for whatever reason and returns a future that
                    // originated from that foreign EventLoop.
                    .hop(to: self.eventLoop)
                    .mapResult { result in
                        if case .failure(let error) = result {
                            logger.warning("scf handler returned an error: \(error)")
                        }
                        return (invocation, result)
                    }
            }.flatMap { invocation, result in
                // 3. Report results to the runtime engine.
                self.runtimeClient.reportResults(logger: logger, invocation: invocation, result: result).peekError { error in
                    logger.error("could not report results to scf runtime engine: \(error)")
                }
            }
        }

        /// Cancels the current run, if we are waiting for next invocation (long poll from the SCF API server).
        /// Only needed for debugging purposes.
        func cancelWaitingForNextInvocation() {
            if self.isGettingNextInvocation {
                self.runtimeClient.cancel()
            }
        }
    }
}

private extension SCF.Context {
    convenience init(logger: Logger, eventLoop: EventLoop, allocator: ByteBufferAllocator, invocation: SCF.Invocation) {
        self.init(requestID: invocation.requestID,
                  memoryLimit: invocation.memoryLimit,
                  timeLimit: .milliseconds(Int(invocation.timeLimit)),
                  logger: logger,
                  eventLoop: eventLoop,
                  allocator: allocator)
    }
}

// TODO: move to nio?
extension EventLoopFuture {
    // Callback does not have side effects, failing with original result.
    func peekError(_ callback: @escaping (Error) -> Void) -> EventLoopFuture<Value> {
        self.flatMapError { error in
            callback(error)
            return self
        }
    }

    // Callback does not have side effects, failing with original result.
    func peekError(_ callback: @escaping (Error) -> EventLoopFuture<Void>) -> EventLoopFuture<Value> {
        self.flatMapError { error in
            let promise = self.eventLoop.makePromise(of: Value.self)
            callback(error).whenComplete { _ in
                promise.completeWith(self)
            }
            return promise.futureResult
        }
    }

    func mapResult<NewValue>(_ callback: @escaping (Result<Value, Error>) -> NewValue) -> EventLoopFuture<NewValue> {
        self.map { value in
            callback(.success(value))
        }.flatMapErrorThrowing { error in
            callback(.failure(error))
        }
    }
}

private extension Result {
    var successful: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
