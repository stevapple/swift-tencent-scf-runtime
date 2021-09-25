//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2021 stevapple and the SwiftTencentSCFRuntime project authors
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
// Copyright (c) 2017-2021 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import NIOCore
@testable import TencentSCFRuntimeCore
import XCTest

class SCFHandlerTest: XCTestCase {
    #if compiler(>=5.5) && canImport(_Concurrency)

    // MARK: - SCFHandler

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testBootstrapSuccess() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct TestBootstrapHandler: SCFHandler {
            typealias In = String
            typealias Out = String

            var initialized = false

            init(context: SCF.InitializationContext) async throws {
                XCTAssertFalse(self.initialized)
                try await Task.sleep(nanoseconds: 100 * 1000 * 1000) // 0.1 seconds
                self.initialized = true
            }

            func handle(context: SCF.Context, event: String) async throws -> String {
                event
            }
        }

        let maxTimes = Int.random(in: 10 ... 20)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handlerType: TestBootstrapHandler.self)
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testBootstrapFailure() {
        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct TestBootstrapHandler: SCFHandler {
            typealias In = String
            typealias Out = Void

            var initialized = false

            init(context: SCF.InitializationContext) async throws {
                XCTAssertFalse(self.initialized)
                try await Task.sleep(nanoseconds: 100 * 1000 * 1000) // 0.1 seconds
                throw TestError("kaboom")
            }

            func handle(context: SCF.Context, event: String) async throws {
                XCTFail("How can this be called if init failed")
            }
        }

        let maxTimes = Int.random(in: 10 ... 20)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handlerType: TestBootstrapHandler.self)
        assertSCFLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testHandlerSuccess() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: SCFHandler {
            typealias In = String
            typealias Out = String

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: String) async throws -> String {
                event
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handlerType: Handler.self)
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testVoidHandlerSuccess() {
        let server = MockSCFServer(behavior: Behavior(result: .success(nil)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: SCFHandler {
            typealias In = String
            typealias Out = Void

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: String) async throws {}
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))

        let result = SCF.run(configuration: configuration, handlerType: Handler.self)
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testHandlerFailure() {
        let server = MockSCFServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: SCFHandler {
            typealias In = String
            typealias Out = String

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: String) async throws -> String {
                throw TestError("boom")
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, handlerType: Handler.self)
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }
    #endif

    // MARK: - EventLoopSCFHandler

    func testEventLoopSuccess() {
        let server = MockSCFServer(behavior: Behavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopSCFHandler {
            typealias In = String
            typealias Out = String

            func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
                context.eventLoop.makeSucceededFuture(event)
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, factory: { context in
            context.eventLoop.makeSucceededFuture(Handler())
        })
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testVoidEventLoopSuccess() {
        let server = MockSCFServer(behavior: Behavior(result: .success(nil)))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopSCFHandler {
            typealias In = String
            typealias Out = Void

            func handle(context: SCF.Context, event: String) -> EventLoopFuture<Void> {
                context.eventLoop.makeSucceededFuture(())
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, factory: { context in
            context.eventLoop.makeSucceededFuture(Handler())
        })
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testEventLoopFailure() {
        let server = MockSCFServer(behavior: Behavior(result: .failure(TestError("boom"))))
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        struct Handler: EventLoopSCFHandler {
            typealias In = String
            typealias Out = String

            func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
                context.eventLoop.makeFailedFuture(TestError("boom"))
            }
        }

        let maxTimes = Int.random(in: 1 ... 10)
        let configuration = SCF.Configuration(lifecycle: .init(maxTimes: maxTimes))
        let result = SCF.run(configuration: configuration, factory: { context in
            context.eventLoop.makeSucceededFuture(Handler())
        })
        assertSCFLifecycleResult(result, shoudHaveRun: maxTimes)
    }

    func testEventLoopBootstrapFailure() {
        let server = MockSCFServer(behavior: FailedBootstrapBehavior())
        XCTAssertNoThrow(try server.start().wait())
        defer { XCTAssertNoThrow(try server.stop().wait()) }

        let result = SCF.run(configuration: .init(), factory: { context in
            context.eventLoop.makeFailedFuture(TestError("kaboom"))
        })
        assertSCFLifecycleResult(result, shouldFailWithError: TestError("kaboom"))
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
        switch self.result {
        case .success(let expected):
            XCTAssertEqual(expected, response, "expecting response to match")
            return .success(())
        case .failure:
            XCTFail("unexpected to fail, but succeeded with: \(response ?? "undefined")")
            return .failure(.internalServerError)
        }
    }

    func process(error: String) -> Result<Void, ProcessErrorError> {
        switch self.result {
        case .success:
            XCTFail("unexpected to succeed, but failed with: \(error)")
            return .failure(.internalServerError)
        case .failure(let expected):
            XCTAssertEqual(expected.description, error, "expecting error to match")
            return .success(())
        }
    }
}
