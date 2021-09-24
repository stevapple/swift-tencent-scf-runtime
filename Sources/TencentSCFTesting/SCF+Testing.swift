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
// Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

// This functionality is designed to help with SCF unit testing with XCTest.
// #if filter is required for release builds which do not support @testable import.
// @testable is used to access of internal functions.
// For exmaple:
//
// func test() {
//     struct MyCloudFunction: EventLoopSCFHandler {
//         typealias In = String
//         typealias Out = String
//
//         func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
//             return context.eventLoop.makeSucceededFuture("echo" + event)
//         }
//     }
//
//     let input = UUID().uuidString.lowercased()
//     var result: String?
//     XCTAssertNoThrow(result = try SCF.test(MyCloudFunction(), with: input))
//     XCTAssertEqual(result, "echo" + input)
// }

#if compiler(>=5.5) && canImport(_Concurrency)
import Dispatch
import Logging
import NIOCore
import NIOPosix
import TencentSCFRuntime

extension SCF {
    public struct TestConfig {
        public var requestID: String
        public var memoryLimit: UInt
        public var timeLimit: DispatchTimeInterval

        public init(requestID: String = "\(DispatchTime.now().uptimeNanoseconds)",
                    memoryLimit: UInt = 128,
                    timeLimit: DispatchTimeInterval = .seconds(5))
        {
            self.requestID = requestID
            self.memoryLimit = memoryLimit
            self.timeLimit = timeLimit
        }
    }

    public static func test<Handler: SCFHandler>(
        _ handlerType: Handler.Type,
        with event: Handler.Event,
        using config: TestConfig = .init()
    ) throws -> Handler.Output {
        let logger = Logger(label: "test")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        let eventLoop = eventLoopGroup.next()

        let promise = eventLoop.makePromise(of: Handler.self)
        let initContext = SCF.InitializationContext(
            logger: logger,
            eventLoop: eventLoop,
            allocator: ByteBufferAllocator()
        )

        let context = SCF.Context(
            requestID: config.requestID,
            traceID: config.traceID,
            invokedFunctionARN: config.invokedFunctionARN,
            timeout: config.timeout,
            logger: logger,
            eventLoop: eventLoop,
            allocator: ByteBufferAllocator()
        )

        promise.completeWithTask {
            try await Handler(context: initContext)
        }
        let handler = try promise.futureResult.wait()

        return try eventLoop.flatSubmit {
            handler.handle(event, context: context)
        }.wait()
    }
}
#endif
