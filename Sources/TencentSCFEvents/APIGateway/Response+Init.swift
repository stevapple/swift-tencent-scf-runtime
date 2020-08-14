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

extension APIGateway.Response {
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
                data: try APIGateway.defaultJSONEncoder.encode(codableBody),
                encoding: .utf8
            ) ?? ""
            self.statusCode = statusCode
        } catch let err as EncodingError {
            self.body = #"{"error":"EncodingError","message":"\#("\(err)".jsonEncoded())"}"#
            self.statusCode = .internalServerError
        } catch let err {
            self.body = #"{"error":"UnexpectedError","message":"\#("\(err)".jsonEncoded())"}"#
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
