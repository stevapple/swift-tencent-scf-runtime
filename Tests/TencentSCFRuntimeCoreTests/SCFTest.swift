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
@testable import TencentSCFRuntimeCore
import XCTest

class SCFTest: XCTestCase {
    func testSuccess() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = Int.random(in: 10 ... 20)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testFailure() {
        let server = MockSCFServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = Int.random(in: 10 ... 20)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handler: FailedHandler("boom"))
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testBootstrapOnce() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: SCFHandler {
            typealias In = String
            typealias Out = String

            var initialized = false

            init(context: SCF.InitializationContext) {
                XCTAssertFalse(self.initialized)
                self.initialized = true
            }

            func handle(context: SCF.Context, event: String, callback: (Result<String, Error>) -> Void) {
                callback(.success(event))
            }
        }

        let maxTimes = Int.random(in: 10 ... 20)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, factory: Handler.init)
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testBootstrapFailure() {
        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let result = SCF.run(factory: { $0.eventLoop.makeFailedFuture(TestError("kaboom")) })
        assertSCFLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
    }

    func testBootstrapFailure2() {
        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: SCFHandler {
            typealias In = String
            typealias Out = Void

            init(context: SCF.InitializationContext) throws {
                throw TestError("kaboom")
            }

            func handle(context: SCF.Context, event: String, callback: (Result<Void, Error>) -> Void) {
                callback(.failure(TestError("should not be called")))
            }
        }

        let result = SCF.run(factory: Handler.init)
        assertSCFLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
    }

    func testBootstrapFailureAndReportErrorFailure() {
        struct Behavior: SCFServerBehavior {
            func getInvocation() -> GetInvocationResult {
                XCTFail("should not get invocation")
                return .failure(.internalServerError)
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
                .failure(.internalServerError)
            }
        }

        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let result = SCF.run(factory: { $0.eventLoop.makeFailedFuture(TestError("kaboom")) })
        assertSCFLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
    }

    func testStartStopInDebugMode() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let signal = Signal.ALRM
        let maxTimes = 1000
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes, stopSignal: signal))

        DispatchQueue(label: "test").async {
            // we need to schedule the signal before we start the long running `SCF.run`, since
            // `SCF.run` will block the main thread.
            usleep(100_000)
            kill(getpid(), signal.rawValue)
        }
        let result = SCF.run(configuration: configuration, factory: { $0.eventLoop.makeSucceededFuture(EchoHandler()) })

        switch result {
        case .success(let invocationCount):
            XCTAssertGreaterThan(invocationCount, 0, "should have stopped before any request made")
            XCTAssertLessThan(invocationCount, maxTimes, "should have stopped before \(maxTimes)")
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTimeout() {
        let timeout: Int64 = 100
        let server = MockSCFServer(behavior: Behavior(requestId: "timeout", event: "\(timeout * 2)"))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: 1),
                                              runtimeEngine: .init(requestTimeout: .milliseconds(timeout)))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shouldFailWithError: SCF.RuntimeError.upstreamError("timeout"))
    }

    func testDisconnect() {
        let server = MockSCFServer(behavior: Behavior(requestId: "disconnect"))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: 1))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shouldFailWithError: SCF.RuntimeError.upstreamError("connectionResetByPeer"))
    }

    func testBigEvent() {
        let event = String(repeating: "*", count: 104_448)
        let server = MockSCFServer(behavior: Behavior(event: event, result: .success(event)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: 1))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shoudHaveRun: 1)
    }

    func testKeepAliveServer() {
        let server = MockSCFServer(behavior: Behavior(), keepAlive: true)
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = 10
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testNoKeepAliveServer() {
        let server = MockSCFServer(behavior: Behavior(), keepAlive: false)
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let maxTimes = 10
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handler: EchoHandler())
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testServerFailure() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Behavior: SCFServerBehavior {
            func getInvocation() -> GetInvocationResult {
                .failure(.internalServerError)
            }

            func process(response: String?) -> Result<Void, ProcessResponseError> {
                .failure(.internalServerError)
            }

            func process(error: ErrorResponse) -> Result<Void, ProcessErrorError> {
                .failure(.internalServerError)
            }

            func process(initError: ErrorResponse) -> Result<Void, ProcessErrorError> {
                XCTFail("should not report init error")
                return .failure(.internalServerError)
            }
        }

        let result = SCF.run(handler: EchoHandler())
        assertSCFLifecycleResult(result, shouldFailWithError: SCF.RuntimeError.badStatusCode(.internalServerError))
    }

    func testDeadline() {
        let delta = Int.random(in: 1 ... 600)

        let milli1 = Date(timeIntervalSinceNow: Double(delta)).millisSinceEpoch
        let milli2 = (DispatchWallTime.now() + .seconds(delta)).millisSinceEpoch
        XCTAssertEqual(Double(milli1), Double(milli2), accuracy: 2.0)

        let now1 = DispatchWallTime.now()
        let now2 = DispatchWallTime(millisSinceEpoch: Date().millisSinceEpoch)
        XCTAssertEqual(Double(now2.rawValue), Double(now1.rawValue), accuracy: 2_000_000.0)

        let future1 = DispatchWallTime.now() + .seconds(delta)
        let future2 = DispatchWallTime(millisSinceEpoch: Date(timeIntervalSinceNow: Double(delta)).millisSinceEpoch)
        XCTAssertEqual(Double(future1.rawValue), Double(future2.rawValue), accuracy: 2_000_000.0)

        let past1 = DispatchWallTime.now() - .seconds(delta)
        let past2 = DispatchWallTime(millisSinceEpoch: Date(timeIntervalSinceNow: Double(-delta)).millisSinceEpoch)
        XCTAssertEqual(Double(past1.rawValue), Double(past2.rawValue), accuracy: 2_000_000.0)

        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertGreaterThan(context.deadline, .now())
    }

    func testGetRemainingTime() {
        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertLessThanOrEqual(context.getRemainingTime(), .seconds(3))
        XCTAssertGreaterThan(context.getRemainingTime(), .milliseconds(800))
    }
}

private struct Behavior: SCFServerBehavior {
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

struct FailedBootstrapBehavior: SCFServerBehavior {
    func getInvocation() -> GetInvocationResult {
        XCTFail("should not get invocation")
        return .failure(.internalServerError)
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
        .success(())
    }
}
