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

import NIO
@testable import TencentSCFRuntimeCore
import XCTest

class StringLambdaTest: XCTestCase {
    func testCallbackSuccess() {
        let server = MockLambdaServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: LambdaHandler {
            typealias In = String
            typealias Out = String

            func handle(context: Lambda.Context, event: String, callback: (Result<String, Error>) -> Void) {
                callback(.success(event))
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testVoidCallbackSuccess() {
        let server = MockLambdaServer(behavior: Behavior(result: .success(nil)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: LambdaHandler {
            typealias In = String
            typealias Out = Void

            func handle(context: Lambda.Context, event: String, callback: (Result<Void, Error>) -> Void) {
                callback(.success(()))
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testCallbackFailure() {
        let server = MockLambdaServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: LambdaHandler {
            typealias In = String
            typealias Out = String

            func handle(context: Lambda.Context, event: String, callback: (Result<String, Error>) -> Void) {
                callback(.failure(TestError("boom")))
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testEventLoopSuccess() {
        let server = MockLambdaServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopLambdaHandler {
            typealias In = String
            typealias Out = String

            func handle(context: Lambda.Context, event: String) -> EventLoopFuture<String> {
                context.eventLoop.makeSucceededFuture(event)
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testVoidEventLoopSuccess() {
        let server = MockLambdaServer(behavior: Behavior(result: .success(nil)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopLambdaHandler {
            typealias In = String
            typealias Out = Void

            func handle(context: Lambda.Context, event: String) -> EventLoopFuture<Void> {
                context.eventLoop.makeSucceededFuture(())
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testEventLoopFailure() {
        let server = MockLambdaServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopLambdaHandler {
            typealias In = String
            typealias Out = String

            func handle(context: Lambda.Context, event: String) -> EventLoopFuture<String> {
                context.eventLoop.makeFailedFuture(TestError("boom"))
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration, handler: Handler())
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testClosureSuccess() {
        let server = MockLambdaServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration) { (_, event: String, callback) in
            callback(.success(event))
        }
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testVoidClosureSuccess() {
        let server = MockLambdaServer(behavior: Behavior(result: .success(nil)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = Lambda.run(configuration: configuration) { (_, _: String, callback) in
            callback(.success(()))
        }
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testClosureFailure() {
        let server = MockLambdaServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = Lambda.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result: Result<Int, Error> = Lambda.run(configuration: configuration) { (_, _: String, callback: (Result<String, Error>) -> Void) in
            callback(.failure(TestError("boom")))
        }
        assertLambdaLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testBootstrapFailure() {
        let server = MockLambdaServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: LambdaHandler {
            typealias In = String
            typealias Out = String

            init(context: Lambda.InitializationContext) throws {
                throw TestError("kaboom")
            }

            func handle(context: Lambda.Context, event: String, callback: (Result<String, Error>) -> Void) {
                callback(.failure(TestError("should not be called")))
            }
        }

        let result = Lambda.run(factory: Handler.init)
        assertLambdaLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
    }
}

private struct Behavior: LambdaServerBehavior {
    let requestId: String
    let event: String
    let result: Result<String?, TestError>

    init(requestId: String = UUID().uuidString.lowercased(), event: String = "hello", result: Result<String?, TestError> = .success("hello")) {
        self.requestId = requestId
        self.event = event
        self.result = result
    }

    func getInvocation() -> GetInvocationResult {
        .success((requestId: self.requestId, event: self.event))
    }

    func process(response: String?) -> Result<Void, ProcessResponseError> {
        XCTAssertEqual(self.requestId, self.requestId, "expecting requestId to match")
        switch self.result {
        case .success(let expected):
            XCTAssertEqual(expected, response, "expecting response to match")
            return .success(())
        case .failure:
            XCTFail("unexpected to fail, but succeeded with: \(response ?? "undefined")")
            return .failure(.internalServerError)
        }
    }

    func process(error: ErrorResponse) -> Result<Void, ProcessErrorError> {
        XCTAssertEqual(self.requestId, self.requestId, "expecting requestId to match")
        switch self.result {
        case .success:
            XCTFail("unexpected to succeed, but failed with: \(error)")
            return .failure(.internalServerError)
        case .failure(let expected):
            XCTAssertEqual(expected.description, error.errorMessage, "expecting error to match")
            return .success(())
        }
    }

    func process(initError: ErrorResponse) -> Result<Void, ProcessErrorError> {
        XCTFail("should not report init error")
        return .failure(.internalServerError)
    }
}
