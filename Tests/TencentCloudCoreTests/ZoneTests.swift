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

@testable import TencentCloudCore
import XCTest

class TencentCloudZoneTests: XCTestCase {
    static let allRegions = Set(TencentCloud.Region.mainland + TencentCloud.Region.overseas)
    struct Wrapped<T: Codable>: Codable {
        let value: T
    }

    func testZoneWithRawAndCodable() throws {
        for region in Self.allRegions {
            let number = UInt8.random(in: UInt8.min ... UInt8.max)
            let zone = TencentCloud.Zone(rawValue: "\(region)-\(number)")
            XCTAssertNotNil(zone)

            let wrapped = Wrapped(value: zone!)
            let json = #"{"value":"\#(zone!.rawValue)"}"#

            let encoded = try JSONEncoder().encode(wrapped)
            let decoded = try JSONDecoder().decode(Wrapped<TencentCloud.Zone>.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(String(data: encoded, encoding: .utf8), json)
            XCTAssertEqual(zone, decoded.value)
        }
    }
}
