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

import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

// https://intl.cloud.tencent.com/document/product/583/12513

public enum APIGateway {
    /// `APIGateway.Request` contains data coming from the API Gateway.
    public struct Request<T: Decodable> {
        public struct Context: Decodable {
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
        public let body: T?
    }

    public enum Stage: String, Decodable {
        case test
        case debug
        case prepub
        case release
    }

    /// `APIGateway.Response` stores response ready for sending to the API Gateway.
    public typealias Response = APIResponse
}

extension APIGateway {
    internal static let defaultJSONDecoder = JSONDecoder()
    internal static let defaultJSONEncoder = JSONEncoder()
}
