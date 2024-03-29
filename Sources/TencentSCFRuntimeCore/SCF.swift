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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Backtrace
import Logging
import NIOCore
import NIOPosix

public enum SCF {
    public typealias Handler = ByteBufferSCFHandler

    /// `ByteBufferSCFHandler` factory.
    /// A function that takes a `InitializationContext` and returns an `EventLoopFuture` of a `ByteBufferSCFHandler`.
    public typealias HandlerFactory = (InitializationContext) -> EventLoopFuture<Handler>

    /// Run a cloud function defined by implementing the `SCFHandler` protocol provided via a `SCFHandlerFactory`.
    /// Use this to initialize all your resources that you want to cache between invocations. This could be database connections and HTTP clients for example.
    /// It is encouraged to use the given `EventLoop`'s conformance to `EventLoopGroup` when initializing NIO dependencies. This will improve overall performance.
    ///
    /// - Parameters:
    ///     - factory: A `ByteBufferSCFHandler` factory.
    ///
    /// - Note: This is a blocking operation that will run forever, as its lifecycle is managed by the Tencent SCF Runtime Engine.
    public static func run(_ factory: @escaping HandlerFactory) {
        self.run(factory: factory)
    }

    #if compiler(>=5.5) && canImport(_Concurrency)
    // for testing and internal use
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    internal static func run<Handler: SCFHandler>(configuration: Configuration = .init(), handlerType: Handler.Type) -> Result<Int, Error> {
        self.run(configuration: configuration, factory: { context -> EventLoopFuture<ByteBufferSCFHandler> in
            let promise = context.eventLoop.makePromise(of: ByteBufferSCFHandler.self)
            promise.completeWithTask {
                try await Handler(context: context)
            }
            return promise.futureResult
        })
    }
    #endif

    // for testing and internal use
    @discardableResult
    internal static func run(configuration: Configuration = .init(), factory: @escaping HandlerFactory) -> Result<Int, Error> {
        let _run = { (configuration: Configuration, factory: @escaping HandlerFactory) -> Result<Int, Error> in
            Backtrace.install()
            var logger = Logger(label: "SCF")
            logger.logLevel = configuration.general.logLevel

            var result: Result<Int, Error>!
            MultiThreadedEventLoopGroup.withCurrentThreadAsEventLoop { eventLoop in
                let lifecycle = Lifecycle(eventLoop: eventLoop, logger: logger, configuration: configuration, factory: factory)
                #if DEBUG
                let signalSource = trap(signal: configuration.lifecycle.stopSignal) { signal in
                    logger.info("intercepted signal: \(signal)")
                    lifecycle.shutdown()
                }
                #endif

                lifecycle.start().flatMap {
                    lifecycle.shutdownFuture
                }.whenComplete { lifecycleResult in
                    #if DEBUG
                    signalSource.cancel()
                    #endif
                    eventLoop.shutdownGracefully { error in
                        if let error = error {
                            preconditionFailure("Failed to shutdown eventloop: \(error)")
                        }
                    }
                    result = lifecycleResult
                }
            }

            logger.info("shutdown completed")
            return result
        }

        // Start local server for debugging in DEBUG mode only.
        #if DEBUG
        if SCF.Env["LOCAL_SCF_SERVER_ENABLED"].flatMap(Bool.init) ?? false {
            do {
                return try SCF.withLocalServer {
                    _run(configuration, factory)
                }
            } catch {
                return .failure(error)
            }
        } else {
            return _run(configuration, factory)
        }
        #else
        return _run(configuration, factory)
        #endif
    }
}
