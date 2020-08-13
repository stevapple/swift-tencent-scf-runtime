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

@testable import TencentSCFEvents
import XCTest

class TencentCloudTests: XCTestCase {
    static let allRegions = Set(TencentCloud.Region.mainland + TencentCloud.Region.overseas)
    struct Wrapped<T: Codable>: Codable {
        let value: T
    }

    func testRegionCountEqual() {
        XCTAssertEqual(TencentCloud.Region.mainland.count + TencentCloud.Region.overseas.count, TencentCloud.Region.regular.count + TencentCloud.Region.financial.count)
        XCTAssertEqual(Self.allRegions, Set(TencentCloud.Region.regular + TencentCloud.Region.financial))
    }

    func testRegionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for region in Self.allRegions {
            let wrapped = Wrapped(value: region)
            let json = #"{"value":"\#(region.rawValue)"}"#
            let encoded = try encoder.encode(wrapped)
            let decoded = try decoder.decode(Wrapped<TencentCloud.Region>.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(String(data: encoded, encoding: .utf8), json)
            XCTAssertEqual(region, decoded.value)
        }
    }

    func testZoneWithRawAndCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for region in Self.allRegions {
            let number = UInt8.random(in: UInt8.min ... UInt8.max)
            let zone = TencentCloud.Zone(rawValue: "\(region)-\(number)")
            XCTAssertNotNil(zone)
            let wrapped = Wrapped(value: zone!)
            let json = #"{"value":"\#(zone!.rawValue)"}"#
            let encoded = try encoder.encode(wrapped)
            let decoded = try decoder.decode(Wrapped<TencentCloud.Zone>.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(String(data: encoded, encoding: .utf8), json)
            XCTAssertEqual(zone, decoded.value)
        }
    }
}
