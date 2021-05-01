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

// https://intl.cloud.tencent.com/document/product/583/12513

extension APIGateway.Request: Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        context = try container.decode(Context.self, forKey: .context)
        headers = try container.decode(HTTPHeaders.self, forKey: .headers)
        path = try container.decode(String.self, forKey: .path)
        httpMethod = try container.decode(HTTPMethod.self, forKey: .httpMethod)
        query = try container.decode([String: String].self, forKey: .query)
        pathParameters = try container.decode([String: String].self, forKey: .pathParameters)
        queryStringParameters = try container.decode([String: String].self, forKey: .queryStringParameters)
        headerParameters = try container.decode([String: String].self, forKey: .headerParameters)

        do {
            body = try container.decodeIfPresent(T.self, forKey: .body)
        } catch {
            let bodyJson = try container.decodeIfPresent(String.self, forKey: .body)
            if let data = bodyJson?.data(using: .utf8) {
                body = try APIGateway.defaultJSONDecoder.decode(T.self, from: data)
            } else {
                body = nil
            }
        }
    }
}
