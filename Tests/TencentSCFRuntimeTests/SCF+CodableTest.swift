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

import Logging
import NIOCore
import NIOFoundationCompat
import NIOPosix
@testable import TencentSCFRuntime
@testable import TencentSCFRuntimeCore
import XCTest

class CodableSCFTest: XCTestCase {
    var eventLoopGroup: EventLoopGroup!
    let allocator = ByteBufferAllocator()

    override func setUp() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    override func tearDown() {
        try! self.eventLoopGroup.syncShutdownGracefully()
    }

    #if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testCodableVoidHandler() {
        struct Handler: SCFHandler {
            typealias Event = Request
            typealias Output = Void

            var expected: Request?

            init(context: SCF.InitializationContext) async throws {}

            func handle(_ event: Request, context: SCF.Context) async throws {
                XCTAssertEqual(event, self.expected)
            }
        }

        XCTAsyncTest {
            let request = Request(requestId: UUID().uuidString)
            var inputBuffer: ByteBuffer?
            var outputBuffer: ByteBuffer?

            var handler = try await Handler(context: self.newInitContext())
            handler.expected = request

            XCTAssertNoThrow(inputBuffer = try JSONEncoder().encode(request, using: self.allocator))
            XCTAssertNoThrow(outputBuffer = try handler.handle(XCTUnwrap(inputBuffer), context: self.newContext()).wait())
            XCTAssertNil(outputBuffer)
        }
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    func testCodableHandler() {
        struct Handler: SCFHandler {
            typealias Event = Request
            typealias Output = Response

            var expected: Request?

            init(context: SCF.InitializationContext) async throws {}

            func handle(_ event: Request, context: SCF.Context) async throws -> Response {
                XCTAssertEqual(event, self.expected)
                return Response(requestId: event.requestId)
            }
        }

        XCTAsyncTest {
            let request = Request(requestId: UUID().uuidString)
            var response: Response?
            var inputBuffer: ByteBuffer?
            var outputBuffer: ByteBuffer?

            var handler = try await Handler(context: self.newInitContext())
            handler.expected = request

            XCTAssertNoThrow(inputBuffer = try JSONEncoder().encode(request, using: self.allocator))
            XCTAssertNoThrow(outputBuffer = try handler.handle(XCTUnwrap(inputBuffer), context: self.newContext()).wait())
            XCTAssertNoThrow(response = try JSONDecoder().decode(Response.self, from: XCTUnwrap(outputBuffer)))
            XCTAssertEqual(response?.requestId, request.requestId)
        }
    }
    #endif

    // convencience method
    func newContext() -> SCF.Context {
        SCF.Context(requestID: UUID().uuidString.lowercased(),
                    memoryLimit: 128,
                    timeLimit: .seconds(3),
                    logger: Logger(label: "test"),
                    eventLoop: self.eventLoopGroup.next(),
                    allocator: ByteBufferAllocator())
    }

    func newInitContext() -> SCF.InitializationContext {
        SCF.InitializationContext(logger: Logger(label: "test"),
                                  eventLoop: self.eventLoopGroup.next(),
                                  allocator: ByteBufferAllocator())
    }
}

private struct Request: Codable, Equatable {
    let requestId: String
    init(requestId: String) {
        self.requestId = requestId
    }
}

private struct Response: Codable, Equatable {
    let requestId: String
    init(requestId: String) {
        self.requestId = requestId
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)
// NOTE: workaround until we have async test support on linux
//         https://github.com/apple/swift-corelibs-xctest/pull/326
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension XCTestCase {
    func XCTAsyncTest(
        expectationDescription: String = "Async operation",
        timeout: TimeInterval = 3,
        file: StaticString = #file,
        line: Int = #line,
        operation: @escaping () async throws -> Void
    ) {
        let expectation = self.expectation(description: expectationDescription)
        Task {
            do { try await operation() }
            catch {
                XCTFail("Error thrown while executing async function @ \(file):\(line): \(error)")
                Thread.callStackSymbols.forEach { print($0) }
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: timeout)
    }
}
#endif
