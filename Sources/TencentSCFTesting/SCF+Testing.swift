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

import Dispatch
import Logging
import NIOCore
import NIOPosix

#if DEBUG
@testable import TencentSCFRuntime
@testable import TencentSCFRuntimeCore

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

    public static func test(_ closure: @escaping SCF.StringClosure,
                            with event: String,
                            using config: TestConfig = .init()) throws -> String {
        try Self.test(StringClosureWrapper(closure), with: event, using: config)
    }

    public static func test(_ closure: @escaping SCF.StringVoidClosure,
                            with event: String,
                            using config: TestConfig = .init()) throws {
        _ = try Self.test(StringVoidClosureWrapper(closure), with: event, using: config)
    }

    public static func test<In: Decodable, Out: Encodable>(
        _ closure: @escaping SCF.CodableClosure<In, Out>,
        with event: In,
        using config: TestConfig = .init()
    ) throws -> Out {
        try Self.test(CodableClosureWrapper(closure), with: event, using: config)
    }

    public static func test<In: Decodable>(
        _ closure: @escaping SCF.CodableVoidClosure<In>,
        with event: In,
        using config: TestConfig = .init()
    ) throws {
        _ = try Self.test(CodableVoidClosureWrapper(closure), with: event, using: config)
    }

    public static func test<In, Out, Handler: EventLoopSCFHandler>(
        _ handler: Handler,
        with event: In,
        using config: TestConfig = .init()
    ) throws -> Out where Handler.In == In, Handler.Out == Out {
        let logger = Logger(label: "test")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        let eventLoop = eventLoopGroup.next()
        let context = Context(requestID: config.requestID,
                              memoryLimit: config.memoryLimit,
                              timeLimit: config.timeLimit,
                              logger: logger,
                              eventLoop: eventLoop,
                              allocator: ByteBufferAllocator())

        return try eventLoop.flatSubmit {
            handler.handle(context: context, event: event)
        }.wait()
    }
}
#endif
