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

import struct Foundation.Data
import class Foundation.JSONEncoder

// https://cloud.tencent.com/document/product/583/12513

/// `APIGateway.Request` contains data coming from the API Gateway.
public enum APIGateway {
    public struct Request: Codable {
        public struct Context: Codable {
            public let identity: [String: String]
            public let serviceId: String
            public let path: String
            public let sourceIp: String
            public let stage: Stage
            public let httpMethod: HTTPMethod
        }

        public let path: String
        public let httpMethod: HTTPMethod
        public let headers: HTTPHeaders
        public let query: [String: String]

        public let pathParameters: [String: String]
        public let queryStringParameters: [String: String]
        public let headerParameters: [String: String]

        public let context: Context
        public let body: String?

        enum CodingKeys: String, CodingKey {
            case context = "requestContext"
            case body
            case headers
            case query = "queryString"
            case path
            case httpMethod

            case pathParameters
            case queryStringParameters
            case headerParameters
        }
    }

    public enum Stage: String, Codable {
        case test
        case debug
        case prepub
        case release
    }

    public struct Response: Codable {
        public let statusCode: HTTPResponseStatus
        public let headers: HTTPHeaders
        public let body: String
        public let isBase64Encoded: Bool

        public init<T: Encodable>(
            statusCode: HTTPResponseStatus,
            headers: HTTPHeaders = [:],
            codableBody: T?
        ) {
            var headers = headers
            headers["Content-Type"] = MIME.json.rawValue
            self.headers = headers
            do {
                self.body = String(
                    data: try JSONEncoder().encode(codableBody),
                    encoding: .utf8
                ) ?? ""
                self.statusCode = statusCode
            } catch let err {
                self.body = #"{"errorType":"FunctionError","errorMsg":"\#(err.localizedDescription)"}"#
                self.statusCode = .internalServerError
            }
            self.isBase64Encoded = false
        }

        public init(
            statusCode: HTTPResponseStatus,
            headers: HTTPHeaders = [:],
            type: MIME? = nil,
            body: String? = nil
        ) {
            self.statusCode = statusCode
            var headers = headers
            if let type = type?.rawValue {
                headers["Content-Type"] = type
            } else {
                headers["Content-Type"] = MIME.text.rawValue
            }
            self.headers = headers
            self.body = body ?? ""
            self.isBase64Encoded = false
        }

        public init(
            statusCode: HTTPResponseStatus,
            headers: HTTPHeaders = [:],
            type: MIME? = nil,
            body: Data
        ) {
            self.statusCode = statusCode
            var headers = headers
            if let type = type?.rawValue {
                headers["Content-Type"] = type
            } else {
                headers["Content-Type"] = MIME.octet.rawValue
            }
            self.headers = headers
            self.body = body.base64EncodedString()
            self.isBase64Encoded = true
        }
    }
}
