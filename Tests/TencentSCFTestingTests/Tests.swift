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

#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore
import TencentSCFRuntime
import TencentSCFTesting
import XCTest

class LambdaTestingTests: XCTestCase {
    func testCodableClosure() {
        struct Request: Codable {
            let name: String
        }

        struct Response: Codable {
            let message: String
        }

        struct MyCloudFunction: SCFHandler {
            typealias In = Request
            typealias Out = Response

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: Request) async throws -> Response {
                Response(message: "echo" + event.name)
            }
        }

        let request = Request(name: UUID().uuidString)
        var response: Response?
        XCTAssertNoThrow(response = try SCF.test(MyCloudFunction.self, with: request))
        XCTAssertEqual(response?.message, "echo" + request.name)
    }

    // DIRTY HACK: To verify the handler was actually invoked, we change a global variable.
    static var VoidSCFHandlerInvokeCount: Int = 0
    func testCodableVoidClosure() {
        struct Request: Codable {
            let name: String
        }

        struct MyCloudFunction: SCFHandler {
            typealias In = Request
            typealias Out = Void

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: Request) async throws {
                LambdaTestingTests.VoidSCFHandlerInvokeCount += 1
            }
        }

        Self.VoidSCFHandlerInvokeCount = 0
        let request = Request(name: UUID().uuidString)
        XCTAssertNoThrow(try SCF.test(MyCloudFunction.self, with: request))
        XCTAssertEqual(Self.VoidSCFHandlerInvokeCount, 1)
    }

    func testInvocationFailure() {
        struct MyError: Error {}

        struct MyCloudFunction: SCFHandler {
            typealias In = String
            typealias Out = Void

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: String) async throws {
                throw MyError()
            }
        }

        XCTAssertThrowsError(try SCF.test(MyCloudFunction.self, with: UUID().uuidString)) { error in
            XCTAssert(error is MyError)
        }
    }

    func testAsyncLongRunning() {
        struct MyCloudFunction: SCFHandler {
            typealias In = String
            typealias Out = String

            init(context: SCF.InitializationContext) {}

            func handle(context: SCF.Context, event: String) async throws -> String {
                try await Task.sleep(nanoseconds: 500 * 1000 * 1000)
                return event
            }
        }

        let uuid = UUID().uuidString
        XCTAssertEqual(try SCF.test(MyCloudFunction.self, with: uuid), uuid)
    }
}
#endif
