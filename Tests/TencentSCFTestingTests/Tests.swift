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

import NIOCore
import TencentSCFRuntime
import TencentSCFTesting
import XCTest

class SCFTestingTests: XCTestCase {
    func testCodableClosure() {
        struct Request: Decodable {
            let name: String
        }

        struct Response: Encodable {
            let message: String
        }

        let myFunction = { (_: SCF.Context, request: Request, callback: (Result<Response, Error>) -> Void) in
            callback(.success(Response(message: "echo" + request.name)))
        }

        let request = Request(name: UUID().uuidString.lowercased())
        var response: Response?
        XCTAssertNoThrow(response = try SCF.test(myFunction, with: request))
        XCTAssertEqual(response?.message, "echo" + request.name)
    }

    func testCodableVoidClosure() {
        struct Request: Decodable {
            let name: String
        }

        let myFunction = { (_: SCF.Context, _: Request, callback: (Result<Void, Error>) -> Void) in
            callback(.success(()))
        }

        let request = Request(name: UUID().uuidString.lowercased())
        XCTAssertNoThrow(try SCF.test(myFunction, with: request))
    }

    func testSCFHandler() {
        struct Request: Decodable {
            let name: String
        }

        struct Response: Encodable {
            let message: String
        }

        struct MyCloudFunction: SCFHandler {
            typealias In = Request
            typealias Out = Response

            func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
                XCTAssertFalse(context.eventLoop.inEventLoop)
                callback(.success(Response(message: "echo" + event.name)))
            }
        }

        let request = Request(name: UUID().uuidString.lowercased())
        var response: Response?
        XCTAssertNoThrow(response = try SCF.test(MyCloudFunction(), with: request))
        XCTAssertEqual(response?.message, "echo" + request.name)
    }

    func testEventLoopSCFHandler() {
        struct MyCloudFunction: EventLoopSCFHandler {
            typealias In = String
            typealias Out = String

            func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
                XCTAssertTrue(context.eventLoop.inEventLoop)
                return context.eventLoop.makeSucceededFuture("echo" + event)
            }
        }

        let input = UUID().uuidString.lowercased()
        var result: String?
        XCTAssertNoThrow(result = try SCF.test(MyCloudFunction(), with: input))
        XCTAssertEqual(result, "echo" + input)
    }

    func testFailure() {
        struct MyError: Error {}

        struct MyCloudFunction: SCFHandler {
            typealias In = String
            typealias Out = Void

            func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
                callback(.failure(MyError()))
            }
        }

        XCTAssertThrowsError(try SCF.test(MyCloudFunction(), with: UUID().uuidString.lowercased())) { error in
            XCTAssert(error is MyError)
        }
    }

    func testAsyncLongRunning() {
        var executed: Bool = false
        let myFunction = { (_: SCF.Context, _: String, callback: @escaping (Result<Void, Error>) -> Void) in
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
                executed = true
                callback(.success(()))
            }
        }

        XCTAssertNoThrow(try SCF.test(myFunction, with: UUID().uuidString.lowercased()))
        XCTAssertTrue(executed)
    }

    func testConfigValues() {
        let timeout: TimeInterval = 4
        let config = SCF.TestConfig(
            requestID: UUID().uuidString.lowercased(),
            memoryLimit: 512,
            timeLimit: .seconds(4)
        )

        let myFunction = { (ctx: SCF.Context, _: String, callback: @escaping (Result<Void, Error>) -> Void) in
            XCTAssertEqual(ctx.requestID, config.requestID)
            XCTAssertEqual(ctx.memoryLimit, config.memoryLimit)
            XCTAssertEqual(ctx.timeLimit, config.timeLimit)

            let secondsSinceEpoch = Double(Int64(bitPattern: ctx.deadline.rawValue)) / -1_000_000_000
            XCTAssertEqual(Date(timeIntervalSince1970: secondsSinceEpoch).timeIntervalSinceNow, timeout, accuracy: 0.1)

            callback(.success(()))
        }

        XCTAssertNoThrow(try SCF.test(myFunction, with: UUID().uuidString.lowercased(), using: config))
    }
}

#if os(Linux)
extension DispatchTimeInterval: Equatable {}
#endif
