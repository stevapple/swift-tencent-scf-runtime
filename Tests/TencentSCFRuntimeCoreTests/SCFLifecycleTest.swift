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

import Logging
import NIO
import NIOHTTP1
@testable import TencentSCFRuntimeCore
import XCTest

class SCFLifecycleTest: XCTestCase {
    func testShutdownFutureIsFulfilledWithStartUpError() {
        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer { XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully()) }

        let eventLoop = eventLoopGroup.next()
        let logger = Logger(label: "TestLogger")
        let testError = TestError("kaboom")
        let lifecycle = SCF.Lifecycle(eventLoop: eventLoop, logger: logger, factory: {
            $0.eventLoop.makeFailedFuture(testError)
        })

        // eventLoop.submit in this case returns an EventLoopFuture<EventLoopFuture<ByteBufferHandler>>
        // which is why we need `wait().wait()`
        XCTAssertThrowsError(_ = try eventLoop.flatSubmit { lifecycle.start() }.wait()) { error in
            XCTAssertEqual(testError, error as? TestError)
        }

        XCTAssertThrowsError(_ = try lifecycle.shutdownFuture.wait()) { error in
            XCTAssertEqual(testError, error as? TestError)
        }
    }

    struct CallbackSCFHandler: ByteBufferSCFHandler {
        let handler: (SCF.Context, ByteBuffer) -> (EventLoopFuture<ByteBuffer?>)
        let shutdown: (SCF.ShutdownContext) -> EventLoopFuture<Void>

        init(_ handler: @escaping (SCF.Context, ByteBuffer) -> (EventLoopFuture<ByteBuffer?>), shutdown: @escaping (SCF.ShutdownContext) -> EventLoopFuture<Void>) {
            self.handler = handler
            self.shutdown = shutdown
        }

        func handle(context: SCF.Context, event: ByteBuffer) -> EventLoopFuture<ByteBuffer?> {
            self.handler(context, event)
        }

        func shutdown(context: SCF.ShutdownContext) -> EventLoopFuture<Void> {
            self.shutdown(context)
        }
    }

    func testShutdownIsCalledWhenSCFShutsdown() {
        let server = MockSCFServer(behavior: BadBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer { XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully()) }

        var count = 0
        let handler = CallbackSCFHandler({ XCTFail("Should not be reached"); return $0.eventLoop.makeSucceededFuture($1) }) { context in
            count += 1
            return context.eventLoop.makeSucceededFuture(())
        }

        let eventLoop = eventLoopGroup.next()
        let logger = Logger(label: "TestLogger")
        let lifecycle = SCF.Lifecycle(eventLoop: eventLoop, logger: logger, factory: {
            $0.eventLoop.makeSucceededFuture(handler)
        })

        XCTAssertNoThrow(_ = try eventLoop.flatSubmit { lifecycle.start() }.wait())
        XCTAssertThrowsError(_ = try lifecycle.shutdownFuture.wait()) { error in
            XCTAssertEqual(.badStatusCode(HTTPResponseStatus.internalServerError), error as? SCF.RuntimeError)
        }
        XCTAssertEqual(count, 1)
    }

    func testSCFResultIfShutsdownIsUnclean() {
        let server = MockSCFServer(behavior: BadBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer { XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully()) }

        var count = 0
        let handler = CallbackSCFHandler({ XCTFail("Should not be reached"); return $0.eventLoop.makeSucceededFuture($1) }) { context in
            count += 1
            return context.eventLoop.makeFailedFuture(TestError("kaboom"))
        }

        let eventLoop = eventLoopGroup.next()
        let logger = Logger(label: "TestLogger")
        let lifecycle = SCF.Lifecycle(eventLoop: eventLoop, logger: logger, factory: {
            $0.eventLoop.makeSucceededFuture(handler)
        })

        XCTAssertNoThrow(_ = try eventLoop.flatSubmit { lifecycle.start() }.wait())
        XCTAssertThrowsError(_ = try lifecycle.shutdownFuture.wait()) { error in
            guard case SCF.RuntimeError.shutdownError(let shutdownError, .failure(let runtimeError)) = error else {
                XCTFail("Unexpected error"); return
            }

            XCTAssertEqual(shutdownError as? TestError, TestError("kaboom"))
            XCTAssertEqual(runtimeError as? SCF.RuntimeError, .badStatusCode(.internalServerError))
        }
        XCTAssertEqual(count, 1)
    }
}

struct BadBehavior: SCFServerBehavior {
    func getInvocation() -> GetInvocationResult {
        .failure(.internalServerError)
    }

    func process(response: String?) -> Result<Void, ProcessResponseError> {
        XCTFail("should not report a response")
        return .failure(.internalServerError)
    }

    func process(error: ErrorResponse) -> Result<Void, ProcessErrorError> {
        XCTFail("should not report an error")
        return .failure(.internalServerError)
    }

    func process(initError: ErrorResponse) -> Result<Void, ProcessErrorError> {
        XCTFail("should not report an error")
        return .failure(.internalServerError)
    }
}
