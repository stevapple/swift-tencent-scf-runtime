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
// Copyright (c) 2017-2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

@testable import TencentSCFEvents
import XCTest

class APIGatewayTests: XCTestCase {
    static let eventBody = #"""
    {
      "requestContext": {
        "serviceId": "service-f94sy04v",
        "path": "/test/{path}",
        "httpMethod": "POST",
        "identity": {
          "secretId": "abdcdxxxxxxxsdfs"
        },
        "sourceIp": "10.0.2.14",
        "stage": "debug"
      },
      "headers": {
        "accept-language": "en-US,en,cn",
        "accept": "text/html,application/xml,application/json",
        "host": "service-3ei3tii4-251000691.ap-guangzhou.apigateway.myqloud.com",
        "user-agent": "User Agent String",
        "x-anonymous-consumer":  "true",
        "x-api-requestid": "24281851d905b02add27dad71656f29b",
        "x-b3-traceid": "24281851d905b02add27dad71656f29b",
        "x-qualifier": "$DEFAULT"
      },
      "body": "{\"test\":\"body\"}",
      "pathParameters": {
        "path": "value"
      },
      "queryStringParameters": {
        "foo": "bar"
      },
      "headerParameters":{
        "Refer": "10.0.2.14"
      },
      "path": "/test/value",
      "queryString": {
        "foo": "bar",
        "bob": "alice"
      },
      "httpMethod": "POST"
    }
    """#

    func testRequestDecodinRequest() {
        let data = Self.eventBody.data(using: .utf8)!
        var req: APIGateway.Request?
        XCTAssertNoThrow(req = try JSONDecoder().decode(APIGateway.Request.self, from: data))

        XCTAssertEqual(req?.path, "/test/value")
        XCTAssertEqual(req?.body, #"{"test":"body"}"#)
        XCTAssertEqual(req?.headers, ["accept-language": "en-US,en,cn",
                                      "accept": "text/html,application/xml,application/json",
                                      "host": "service-3ei3tii4-251000691.ap-guangzhou.apigateway.myqloud.com",
                                      "user-agent": "User Agent String",
                                      "x-anonymous-consumer":  "true",
                                      "x-api-requestid": "24281851d905b02add27dad71656f29b",
                                      "x-b3-traceid": "24281851d905b02add27dad71656f29b",
                                      "x-qualifier": "$DEFAULT"])
        XCTAssertEqual(req?.query, ["foo": "bar",
                                    "bob": "alice"])
        XCTAssertEqual(req?.httpMethod, .POST)

        XCTAssertEqual(req?.pathParameters, ["path": "value"])
        XCTAssertEqual(req?.queryStringParameters, ["foo": "bar"])
        XCTAssertEqual(req?.headerParameters, ["Refer": "10.0.2.14"])

        XCTAssertEqual(req?.context.sourceIp, "10.0.2.14")
        XCTAssertEqual(req?.context.serviceId, "service-f94sy04v")
        XCTAssertEqual(req?.context.path, "/test/{path}")
        XCTAssertEqual(req?.context.httpMethod, .POST)
        XCTAssertEqual(req?.context.stage, .debug)
        XCTAssertEqual(req?.context.identity, ["secretId": "abdcdxxxxxxxsdfs"])
    }

    func testResponseEncodingWithText() {
        let resp = APIGateway.Response(
            statusCode: .ok,
            headers: ["Content-Type": "text/plain"],
            body: "abc123"
        )

        var data: Data?
        XCTAssertNoThrow(data = try JSONEncoder().encode(resp))
        var json: APIGateway.Response?
        XCTAssertNoThrow(json = try JSONDecoder().decode(APIGateway.Response.self, from: XCTUnwrap(data)))

        XCTAssertEqual(json?.statusCode, resp.statusCode)
        XCTAssertEqual(json?.body, resp.body)
        XCTAssertEqual(json?.isBase64Encoded, false)
        XCTAssertEqual(json?.headers["Content-Type"], "text/plain")
    }

    func testResponseEncodingWithData() {
        let body = #"{"hello":"swift"}"#
        let resp = APIGateway.Response(
            statusCode: .ok,
            headers: ["Content-Type": "application/json"],
            body: body.data(using: .utf8)!
        )

        var data: Data?
        XCTAssertNoThrow(data = try JSONEncoder().encode(resp))
        var json: APIGateway.Response?
        XCTAssertNoThrow(json = try JSONDecoder().decode(APIGateway.Response.self, from: XCTUnwrap(data)))

        guard let newResp = json else {
            XCTFail("Expected to have value")
            return
        }

        XCTAssertEqual(newResp.statusCode, resp.statusCode)
        XCTAssertEqual(newResp.isBase64Encoded, true)
        XCTAssertEqual(newResp.headers["Content-Type"], "application/json")
        XCTAssertEqual(Data(base64Encoded: newResp.body), body.data(using: .utf8))
    }
}
