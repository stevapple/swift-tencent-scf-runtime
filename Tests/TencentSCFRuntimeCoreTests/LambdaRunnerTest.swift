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

@testable import TencentSCFRuntimeCore
import XCTest

class LambdaRunnerTest: XCTestCase {
    func testSuccess() {
        struct Behavior: LambdaServerBehavior {
            let requestId = UUID().uuidString.lowercased()
            let event = "hello"
            func getInvocation() -> GetInvocationResult {
                .success((self.requestId, self.event))
            }

            func process(response: String?) -> Result<Void, ProcessResponseError> {
                XCTAssertEqual(self.event, response, "expecting response to match")
                return .success(())
            }

            func process(error: ErrorResponse) -> Result<Void, ProcessErrorError> {
                XCTFail("should not report error")
                return .failure(.internalServerError)
            }

            func process(initError: ErrorResponse) -> Result<Void, ProcessErrorError> {
                XCTFail("should not report init error")
                return .failure(.internalServerError)
            }
        }
        XCTAssertNoThrow(try runLambda(behavior: Behavior(), handler: EchoHandler()))
    }

    func testFailure() {
        struct Behavior: LambdaServerBehavior {
            static let error = "boom"
            let requestId = UUID().uuidString.lowercased()
            func getInvocation() -> GetInvocationResult {
                .success((requestId: self.requestId, event: "hello"))
            }

            func process(response: String?) -> Result<Void, ProcessResponseError> {
                XCTFail("should report error")
                return .failure(.internalServerError)
            }

            func process(error: ErrorResponse) -> Result<Void, ProcessErrorError> {
                XCTAssertEqual(Behavior.error, error.errorMessage, "expecting error to match")
                return .success(())
            }

            func process(initError: ErrorResponse) -> Result<Void, ProcessErrorError> {
                XCTFail("should not report init error")
                return .failure(.internalServerError)
            }
        }
        XCTAssertNoThrow(try runLambda(behavior: Behavior(), handler: FailedHandler(Behavior.error)))
    }
}
