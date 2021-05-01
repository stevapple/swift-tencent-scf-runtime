//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2020-2021 stevapple and the SwiftTencentSCFRuntime project authors
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

public struct APIResponse: Encodable {
    public let statusCode: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let body: String
    public let isBase64Encoded: Bool

    public init(
        statusCode: HTTPResponseStatus,
        headers: HTTPHeaders = [:],
        body: @autoclosure () throws -> Body = .null
    ) {
        let rawBody: Body
        do {
            rawBody = try body()
        } catch let err {
            self.headers = headers.merging(["Content-Type": "application/json"]) { _, `default` in `default` }
            self.statusCode = .internalServerError
            self.isBase64Encoded = false
            if let err = err as? EncodingError {
                self.body = #"{"error":"EncodingError","message":"\#("\(err)".jsonEncoded())"}"#
            } else {
                self.body = #"{"error":"UnexpectedError","message":"\#("\(err)".jsonEncoded())"}"#
            }
            return
        }

        self.statusCode = statusCode
        self.headers = headers.merging(["Content-Type": rawBody.defaultMIME]) { custom, _ in custom }

        switch rawBody {
        case .data(let dataBody):
            self.body = dataBody.base64EncodedString()
            self.isBase64Encoded = true
        case .json(let stringBody), .string(let stringBody):
            self.body = stringBody
            self.isBase64Encoded = false
        case .null:
            self.body = ""
            self.isBase64Encoded = true
        }
    }

    public enum Body {
        case json(String)
        case data(Data)
        case string(String)
        case null

        public static func codable<T: Encodable>(_ body: T) throws -> Self {
            .json(String(data: try APIGateway.defaultJSONEncoder.encode(body), encoding: .utf8) ?? "")
        }

        var defaultMIME: String {
            switch self {
            case .json: return "application/json"
            case .data: return "application/octet-stream"
            case .string: return "text/plain"
            case .null: return "text/plain"
            }
        }
    }
}

