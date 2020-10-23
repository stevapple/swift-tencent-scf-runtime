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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
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

    static let simpleEventBody = #"""
    {
      "requestContext": {
        "serviceId": "service-f94sy04v",
        "path": "/test",
        "httpMethod": "GET",
        "identity": {},
        "sourceIp": "10.0.2.14",
        "stage": "debug"
      },
      "headers": {
        "accept-language": "en-US,en,cn",
        "accept": "text/html,application/xml,application/json",
        "host": "service-3ei3tii4-251000691.ap-guangzhou.apigateway.myqloud.com",
        "user-agent": "User Agent String",
      },
      "pathParameters": {},
      "queryStringParameters": {},
      "headerParameters":{},
      "path": "/test",
      "queryString": {},
      "httpMethod": "GET"
    }
    """#

    func testRequestDecodingRequest() {
        struct Body: Decodable, Equatable {
            let test: String
        }
        let data = Self.eventBody.data(using: .utf8)!
        var req: APIGateway.Request<Body>?
        XCTAssertNoThrow(req = try JSONDecoder().decode(APIGateway.Request<Body>.self, from: data))

        XCTAssertEqual(req?.path, "/test/value")
        XCTAssertEqual(req?.body, Body(test: "body"))
        XCTAssertEqual(req?.headers, ["accept-language": "en-US,en,cn",
                                      "accept": "text/html,application/xml,application/json",
                                      "host": "service-3ei3tii4-251000691.ap-guangzhou.apigateway.myqloud.com",
                                      "user-agent": "User Agent String",
                                      "x-anonymous-consumer": "true",
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

    func testRequestDecodingSimpleRequest() {
        let data = Self.simpleEventBody.data(using: .utf8)!
        var req: APIGateway.Request<String>?
        XCTAssertNoThrow(req = try JSONDecoder().decode(APIGateway.Request<String>.self, from: data))

        XCTAssertEqual(req?.path, "/test")
        XCTAssertNil(req?.body)
        XCTAssertEqual(req?.headers, ["accept-language": "en-US,en,cn",
                                      "accept": "text/html,application/xml,application/json",
                                      "host": "service-3ei3tii4-251000691.ap-guangzhou.apigateway.myqloud.com",
                                      "user-agent": "User Agent String"])
        XCTAssertEqual(req?.query, [:])
        XCTAssertEqual(req?.httpMethod, .GET)

        XCTAssertEqual(req?.pathParameters, [:])
        XCTAssertEqual(req?.queryStringParameters, [:])
        XCTAssertEqual(req?.headerParameters, [:])

        XCTAssertEqual(req?.context.sourceIp, "10.0.2.14")
        XCTAssertEqual(req?.context.serviceId, "service-f94sy04v")
        XCTAssertEqual(req?.context.path, "/test")
        XCTAssertEqual(req?.context.httpMethod, .GET)
        XCTAssertEqual(req?.context.stage, .debug)
        XCTAssertEqual(req?.context.identity, [:])
    }

    func testRequestDecodingWrongBody() {
        struct WrongBody: Decodable {
            let body: String
        }
        let data = Self.eventBody.data(using: .utf8)!
        XCTAssertThrowsError(_ = try JSONDecoder().decode(APIGateway.Request<WrongBody>.self, from: data))
    }

    func testResponseEncodingWithText() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let resp = APIGateway.Response(
            statusCode: .ok,
            body: .string("abc123")
        )
        let expectedJson = #"{"body":"abc123","headers":{"Content-Type":"text\/plain"},"isBase64Encoded":false,"statusCode":200}"#

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertEqual(json, expectedJson)
        } else {
            XCTFail("Expect output JSON")
        }
    }

    func testResponseEncodingWithData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let body = #"{"hello":"swift"}"#
        let resp = APIGateway.Response(
            statusCode: .ok,
            body: .data(body.data(using: .utf8)!)
        )
        let expectedJson = #"{"body":"\#(body.data(using: .utf8)!.base64EncodedString())","headers":{"Content-Type":"application\/octet-stream"},"isBase64Encoded":true,"statusCode":200}"#

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertEqual(json, expectedJson)
        } else {
            XCTFail("Expect output JSON")
        }
    }

    func testResponseEncodingWithCodable() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        struct Point: Encodable, Equatable {
            let x, y: Double
        }
        let point = Point(x: 1.01, y: -0.01)
        let resp = APIGateway.Response(
            statusCode: .ok,
            body: try .codable(point)
        )
        let expectedJson = [
            #"{"body":"{\"x\":1.01,\"y\":-0.01}","headers":{"Content-Type":"application\/json"},"isBase64Encoded":false,"statusCode":200}"#,
            #"{"body":"{\"y\":-0.01,\"x\":1.01}","headers":{"Content-Type":"application\/json"},"isBase64Encoded":false,"statusCode":200}"#,
        ]

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertTrue(expectedJson.contains(json))
        } else {
            XCTFail("Expect output JSON")
        }
    }

    func testResponseEncodingWithNil() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let resp = APIGateway.Response(statusCode: .ok)
        let expectedJson = #"{"body":"","headers":{"Content-Type":"text\/plain"},"isBase64Encoded":true,"statusCode":200}"#

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertEqual(json, expectedJson)
        } else {
            XCTFail("Expect output JSON")
        }
    }

    func testResponseEncodingWithCustomMIME() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let mime = "application/x-javascript"
        let resp = APIGateway.Response(
            statusCode: .ok,
            headers: ["Content-Type": mime],
            body: .string("console.log(\"Hello world!\");")
        )
        let expectedJson = #"{"body":"console.log(\"Hello world!\");","headers":{"Content-Type":"application\/x-javascript"},"isBase64Encoded":false,"statusCode":200}"#

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertEqual(json, expectedJson)
        } else {
            XCTFail("Expect output JSON")
        }
    }

    func testResponseEncodingWithEncodingError() {
        struct NotReallyEncodable: Encodable {
            let value: String = "NotReallyEncodable"

            func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue(self.value, .init(codingPath: encoder.codingPath, debugDescription: "You're testing something not really Encodable! Good luck."))
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let resp = APIGateway.Response(
            statusCode: .ok,
            body: try .codable(NotReallyEncodable())
        )
        let expectedJson = #"{"body":"{\"error\":\"EncodingError\",\"message\":\"invalidValue(\\\"NotReallyEncodable\\\", Swift.EncodingError.Context(codingPath: [], debugDescription: \\\"You\\\\'re testing something not really Encodable! Good luck.\\\"\"}","headers":{"Content-Type":"application\/json"},"isBase64Encoded":false,"statusCode":500}"#

        var data: Data?
        XCTAssertNoThrow(data = try encoder.encode(resp))
        if let data = data,
            let json = String(data: data, encoding: .utf8)
        {
            XCTAssertEqual(json, expectedJson)
        } else {
            XCTFail("Expect output JSON")
        }
    }
}
