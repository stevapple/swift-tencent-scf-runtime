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

// https://cloud.tencent.com/document/product/583/12513

/// `APIGateway.Request` contains data coming from the API Gateway.
public enum APIGateway {
    public struct Request: Codable {
        public struct Context: Codable {
            public let identity: [String: String]
            public let serviceId: String
            public let requestId: String
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
        public let stageVariables: [String: String]

        public let context: Context
        public let body: String

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
            case stageVariables
        }
    }

    public enum Stage: String, Codable {
        case test
        case prepub
        case release
    }

    public struct Response: Codable {
        public let statusCode: HTTPResponseStatus
        public let headers: HTTPHeaders?
        public let body: String?
        public let isBase64Encoded: Bool

        public init(
            statusCode: HTTPResponseStatus,
            headers: HTTPHeaders? = nil,
            body: String? = nil,
            isBase64Encoded: Bool = false
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body
            self.isBase64Encoded = isBase64Encoded
        }

        public init(
            statusCode: HTTPResponseStatus,
            headers: HTTPHeaders? = nil,
            body: Data? = nil
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body?.base64EncodedString()
            self.isBase64Encoded = true
        }
    }
}
