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

    func testCodableVoidClosureWrapper() {
        let request = Request(requestId: UUID().uuidString.lowercased())
        var inputBuffer: ByteBuffer?
        var outputBuffer: ByteBuffer?

        let closureWrapper = CodableVoidClosureWrapper { (_, _: Request, completion) in
            XCTAssertEqual(request, request)
            completion(.success(()))
        }

        XCTAssertNoThrow(inputBuffer = try JSONEncoder().encode(request, using: self.allocator))
        XCTAssertNoThrow(outputBuffer = try closureWrapper.handle(context: self.newContext(), event: XCTUnwrap(inputBuffer)).wait())
        XCTAssertNil(outputBuffer)
    }

    func testCodableClosureWrapper() {
        let request = Request(requestId: UUID().uuidString.lowercased())
        var inputBuffer: ByteBuffer?
        var outputBuffer: ByteBuffer?
        var response: Response?

        let closureWrapper = CodableClosureWrapper { (_, req: Request, completion: (Result<Response, Error>) -> Void) in
            XCTAssertEqual(request, request)
            completion(.success(Response(requestId: req.requestId)))
        }

        XCTAssertNoThrow(inputBuffer = try JSONEncoder().encode(request, using: self.allocator))
        XCTAssertNoThrow(outputBuffer = try closureWrapper.handle(context: self.newContext(), event: XCTUnwrap(inputBuffer)).wait())
        XCTAssertNoThrow(response = try JSONDecoder().decode(Response.self, from: XCTUnwrap(outputBuffer)))
        XCTAssertEqual(response?.requestId, request.requestId)
    }

    // convencience method
    func newContext() -> SCF.Context {
        SCF.Context(requestID: UUID().uuidString.lowercased(),
                    memoryLimit: 128,
                    timeLimit: .seconds(3),
                    logger: Logger(label: "test"),
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
