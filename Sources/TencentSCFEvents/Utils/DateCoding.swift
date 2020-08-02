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
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval

protocol DateCodingHelper {
    static func decode(from decoder: Decoder) throws -> Date
    static func encode(_ date: Date, to encoder: Encoder) throws
}

extension DateCodingHelper {
    static func decodeIfPresent(from decoder: Decoder) throws -> Date? {
        if try decoder.singleValueContainer().decodeNil() {
            return nil
        } else {
            return try decode(from: decoder)
        }
    }

    static func encodeIfPresent(_ date: Date?, to encoder: Encoder) throws {
        if let rawDate = date {
            try encode(rawDate, to: encoder)
        }
    }
}

enum DateCoding {
    enum ISO8601: DateCodingHelper {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Self.dateFormatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription:
                    "Expected date to be in ISO 8601 date format, but `\(string)` does not forfill format")
            }
            return date
        }

        static func encode(_ date: Date, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let string = Self.dateFormatter.string(from: date)
            try container.encode(string)
        }

        static let dateFormatter = ISO8601DateFormatter()
    }

    enum ISO8601WithFractionalSeconds: DateCodingHelper {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Self.dateFormatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription:
                    "Expected date to be in ISO 8601 date format with fractional seconds, but `\(string)` does not forfill format")
            }
            return date
        }

        static func encode(_ date: Date, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let string = Self.dateFormatter.string(from: date)
            try container.encode(string)
        }

        static let dateFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime,
                .withColonSeparatorInTimeZone,
                .withFractionalSeconds,
            ]
            return formatter
        }()
    }

    enum RFC5322: DateCodingHelper {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            var string = try container.decode(String.self)
            // RFC5322 dates sometimes have the alphabetic version of the timezone in brackets after the numeric version. The date formatter
            // fails to parse this so we need to remove this before parsing.
            if let bracket = string.firstIndex(of: "(") {
                string = String(string[string.startIndex ..< bracket].trimmingCharacters(in: .whitespaces))
            }
            guard let date = Self.dateFormatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription:
                    "Expected date to be in RFC 5322 date-time format with fractional seconds, but `\(string)` does not forfill format")
            }
            return date
        }

        static func encode(_ date: Date, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let string = Self.dateFormatter.string(from: date)
            try container.encode(string)
        }

        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, d MMM yyy HH:mm:ss z"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
    }

    enum UnixTimestamp: DateCodingHelper {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(UInt.self)
            let date = Date(timeIntervalSince1970: .init(timestamp))
            return date
        }

        static func encode(_ date: Date, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let timestamp = UInt(date.timeIntervalSince1970)
            try container.encode(timestamp)
        }
    }

    enum UnixTimestampWithFractionalSeconds: DateCodingHelper {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(TimeInterval.self)
            let date = Date(timeIntervalSince1970: timestamp)
            return date
        }

        static func encode(_ date: Date, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let timestamp = date.timeIntervalSince1970
            try container.encode(timestamp)
        }
    }
}

extension KeyedEncodingContainerProtocol {
    mutating func encode(_ date: Date, forKey key: Self.Key, using coding: DateCodingHelper.Type) throws {
        try coding.encode(date, to: self.superEncoder(forKey: key))
    }

    mutating func encode(_ date: Date?, forKey key: Self.Key, using coding: DateCodingHelper.Type) throws {
        if let rawDate = date {
            try coding.encode(rawDate, to: self.superEncoder(forKey: key))
        } else {
            try self.encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ date: Date?, forKey key: Self.Key, using coding: DateCodingHelper.Type) throws {
        if let rawDate = date {
            try coding.encode(rawDate, to: self.superEncoder(forKey: key))
        }
    }
}

extension KeyedDecodingContainerProtocol {
    func decode(_ type: Date.Type, forKey key: Self.Key, using coding: DateCodingHelper.Type) throws -> Date {
        try coding.decode(from: superDecoder(forKey: key))
    }

    func decodeIfPresent(_ type: Date.Type, forKey key: Self.Key, using coding: DateCodingHelper.Type) throws -> Date? {
        if contains(key) {
            return try coding.decode(from: superDecoder(forKey: key))
        } else {
            return nil
        }
    }
}
