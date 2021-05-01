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

// https://intl.cloud.tencent.com/document/product/583/9708

public enum CTimer {
    public struct Event: Decodable, Equatable {
        private static let type: String = "Timer"
        public let trigger: String
        public var time: Date
        public let message: String

        enum CodingKeys: String, CodingKey {
            case type = "Type"
            case trigger = "TriggerName"
            case time = "Time"
            case message = "Message"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            guard type == Self.type else {
                throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: #"Expected type to be "\#(Self.type)", but `\#(type)` does not match"#)
            }
            trigger = try container.decode(String.self, forKey: .trigger)
            time = try container.decode(Date.self, forKey: .time, using: DateCoding.ISO8601.self)
            message = try container.decode(String.self, forKey: .message)
        }
    }
}
