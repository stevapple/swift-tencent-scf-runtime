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

public struct MIME: RawRepresentable, CustomStringConvertible, Equatable, Hashable {
    public typealias RawValue = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        self.rawValue
    }

    public static var json: Self { MIME(rawValue: "application/json") }
    public static var xml: Self { MIME(rawValue: "text/xml") }
    public static var html: Self { MIME(rawValue: "text/html") }
    public static var text: Self { MIME(rawValue: "text/plain") }
    public static var octet: Self { MIME(rawValue: "application/octet-stream") }
}

extension MIME: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let region = try container.decode(String.self)
        self.init(rawValue: region)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
