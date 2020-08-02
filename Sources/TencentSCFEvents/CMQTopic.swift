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

import struct Foundation.Date

// https://cloud.tencent.com/document/product/583/11517

public enum CMQ {
    public enum Topic {
        public struct Event: Codable, Equatable {
            public let records: [Record]

            public enum CodingKeys: String, CodingKey {
                case records = "Records"
            }
        }

        public struct Record: Codable, Equatable {
            internal static let type: String = "topic"

            public let topicOwner: UInt64
            public let topicName: String
            public let subscriptionName: String
            public let message: Message

            enum WrappingCodingKeys: String, CodingKey {
                case cmq = "CMQ"
            }

            enum CodingKeys: String, CodingKey {
                case type
                case topicOwner
                case topicName
                case subscriptionName
            }

            public init(from decoder: Decoder) throws {
                let wrapperContainer = try decoder.container(keyedBy: WrappingCodingKeys.self)
                let container = try wrapperContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .cmq)
                let type = try container.decode(String.self, forKey: .type)
                guard type == Self.type else {
                    throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: #"Expected type to be "\#(Self.type)", but `\#(type)` does not match"#)
                }

                message = try .init(from: try wrapperContainer.superDecoder(forKey: .cmq))
                topicOwner = try container.decode(UInt64.self, forKey: .topicOwner)
                topicName = try container.decode(String.self, forKey: .topicName)
                subscriptionName = try container.decode(String.self, forKey: .subscriptionName)
            }

            public func encode(to encoder: Encoder) throws {
                var wrapperContainer = encoder.container(keyedBy: WrappingCodingKeys.self)
                try wrapperContainer.encode(message, forKey: .cmq)
                var container = wrapperContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .cmq)
                try container.encode(Self.type, forKey: .type)
                try container.encode(topicOwner, forKey: .topicOwner)
                try container.encode(topicName, forKey: .topicName)
                try container.encode(subscriptionName, forKey: .subscriptionName)
            }
        }

        public struct Message: Codable, Equatable {
            internal static let separator: Character = ","

            public let id: String
            public let body: String
            public let tags: [String]

            public let requestId: String
            public let publishTime: Date

            enum CodingKeys: String, CodingKey {
                case publishTime
                case messageId = "msgId"
                case requestId
                case messageBody = "msgBody"
                case messageTags = "msgTag"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .messageId)
                body = try container.decode(String.self, forKey: .messageBody)

                let tagString = try container.decode(String.self, forKey: .messageTags)
                tags = tagString.split(separator: Self.separator)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                requestId = try container.decode(String.self, forKey: .requestId)
                publishTime = try container.decode(Date.self, forKey: .publishTime, using: DateCoding.ISO8601WithFractionalSeconds.self)
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .messageId)
                try container.encode(body, forKey: .messageBody)
                try container.encode(tags.joined(separator: .init(Self.separator)), forKey: .messageTags)
                try container.encode(publishTime, forKey: .publishTime, using: DateCoding.ISO8601WithFractionalSeconds.self)
                try container.encode(requestId, forKey: .requestId)
            }
        }
    }
}
