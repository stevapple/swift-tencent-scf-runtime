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
//
// This source file was part of the SwiftAWSLambdaRuntime open source project
//
// Copyright (c) 2017-2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval

fileprivate enum DateCoding { }

extension DateCoding {
    enum ISO8601 {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Self.dateFormatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription:
                    "Expected date to be in iso8601 date format, but `\(string)` does not forfill format")
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
}

@propertyWrapper
public struct ISO8601DateCoding: Codable {
    fileprivate typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

@propertyWrapper
public struct ISO8601DateCodingOptional: Codable {
    fileprivate typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}

extension DateCoding {
    enum ISO8601WithFractionalSeconds {
        static func decode(from decoder: Decoder) throws -> Date {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Self.dateFormatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription:
                    "Expected date to be in iso8601 date format with fractional seconds but `\(string)` does not forfill format")
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
}

@propertyWrapper
public struct ISO8601DateWithFractionalSecondsCoding: Codable {
    fileprivate typealias Helper = DateCoding.ISO8601WithFractionalSeconds

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

@propertyWrapper
public struct ISO8601DateWithFractionalSecondsCodingOptional: Codable {
    fileprivate typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}

extension DateCoding {
    enum RFC5322 {
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
                    "Expected date to be in RFC5322 date-time format with fractional seconds, but `\(string)` does not forfill format")
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
}

@propertyWrapper
public struct RFC5322DateTimeCoding: Decodable {
    fileprivate typealias Helper = DateCoding.RFC5322

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

@propertyWrapper
public struct RFC5322DateTimeCodingOptional: Codable {
    fileprivate typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}

extension DateCoding {
    enum UnixTimestamp {
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
}

@propertyWrapper
public struct UnixTimestampCoding: Decodable {
    fileprivate typealias Helper = DateCoding.UnixTimestamp

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

@propertyWrapper
public struct UnixTimestampCodingOptional: Codable {
    fileprivate typealias Helper = DateCoding.UnixTimestamp

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}

extension DateCoding {
    enum UnixTimestampWithFractionalSeconds {
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

@propertyWrapper
public struct UnixTimestampWithFractionalSecondsCoding: Decodable {
    fileprivate typealias Helper = DateCoding.UnixTimestampWithFractionalSeconds

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

@propertyWrapper
public struct UnixTimestampWithFractionalSecondsCodingOptional: Codable {
    fileprivate typealias Helper = DateCoding.UnixTimestampWithFractionalSeconds

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}