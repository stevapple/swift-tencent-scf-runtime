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

protocol CodableDateWrapper: Codable {
    associatedtype Helper: DateCodingHelper
    var wrappedValue: Date { get }
    init(wrappedValue: Date)
    init(from decoder: Decoder) throws
    func encode(to encoder: Encoder) throws
}

protocol CodableDateOptionalWrapper: Codable {
    associatedtype Helper: DateCodingHelper
    var wrappedValue: Date? { get }
    init(wrappedValue: Date?)
    init(from decoder: Decoder) throws
    func encode(to encoder: Encoder) throws
}

extension CodableDateWrapper {
    public func encode(to encoder: Encoder) throws {
        try Helper.encode(wrappedValue, to: encoder)
    }
}

extension CodableDateOptionalWrapper {
    public func encode(to encoder: Encoder) throws {
        if let value = wrappedValue {
            try Helper.encode(value, to: encoder)
        }
    }
}

@propertyWrapper
public struct ISO8601DateCoding: CodableDateWrapper {
    internal typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }
}

@propertyWrapper
public struct ISO8601DateCodingOptional: CodableDateOptionalWrapper {
    internal typealias Helper = DateCoding.ISO8601

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decodeIfPresent(from: decoder)
    }
}

@propertyWrapper
public struct ISO8601DateWithFractionalSecondsCoding: CodableDateWrapper {
    internal typealias Helper = DateCoding.ISO8601WithFractionalSeconds

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }
}

@propertyWrapper
public struct ISO8601DateWithFractionalSecondsCodingOptional: CodableDateOptionalWrapper {
    internal typealias Helper = DateCoding.ISO8601WithFractionalSeconds

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decodeIfPresent(from: decoder)
    }
}

@propertyWrapper
public struct RFC5322DateTimeCoding: CodableDateWrapper {
    internal typealias Helper = DateCoding.RFC5322

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }
}

@propertyWrapper
public struct RFC5322DateTimeCodingOptional: CodableDateOptionalWrapper {
    internal typealias Helper = DateCoding.RFC5322

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decodeIfPresent(from: decoder)
    }
}

@propertyWrapper
public struct UnixTimestampCoding: CodableDateWrapper {
    internal typealias Helper = DateCoding.UnixTimestamp

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }
}

@propertyWrapper
public struct UnixTimestampCodingOptional: CodableDateOptionalWrapper {
    internal typealias Helper = DateCoding.UnixTimestamp

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decodeIfPresent(from: decoder)
    }
}

@propertyWrapper
public struct UnixTimestampWithFractionalSecondsCoding: CodableDateWrapper {
    internal typealias Helper = DateCoding.UnixTimestampWithFractionalSeconds

    public let wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decode(from: decoder)
    }
}

@propertyWrapper
public struct UnixTimestampWithFractionalSecondsCodingOptional: CodableDateOptionalWrapper {
    internal typealias Helper = DateCoding.UnixTimestampWithFractionalSeconds

    public let wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        self.wrappedValue = try Helper.decodeIfPresent(from: decoder)
    }
}
