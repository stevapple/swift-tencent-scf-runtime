//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2021 stevapple and the SwiftTencentSCFRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Gzip
import struct Foundation.Data
import struct Foundation.Date

// https://intl.cloud.tencent.com/document/product/583/38845

import class Foundation.JSONDecoder

public enum CLS {
    public struct Logs: Decodable {
        public let topicId: String
        public let topicName: String
        public let records: [CLS.Record]

        public init(from decoder: Decoder) throws {
            let rawContainer = try decoder.singleValueContainer()
            let data = try rawContainer.decode(CLS.Raw.self).data.gunzipped()
            
            let _self = try CLS.jsonDecoder.decode(CLS._Logs.self, from: data)
            self.topicId = _self.topicId
            self.topicName = _self.topicName
            self.records = _self.records
        }
    }

    public struct Record: Decodable {
        public let timestamp: UInt
        public let content: String

        public var date: Date {
            Date(timeIntervalSince1970: Double(timestamp) / 1000)
        }

        enum CodingKeys: String, CodingKey {
            case timestamp
            case content
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let timestring = try container.decode(String.self, forKey: .timestamp)
            guard let timestamp = UInt(timestring) else {
                throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription: "Expected timestamp to be unsigned numbers")
            }
            self.timestamp = timestamp
            self.content = try container.decode(String.self, forKey: .content)
        }
    }

    internal static let jsonDecoder = JSONDecoder()
}
