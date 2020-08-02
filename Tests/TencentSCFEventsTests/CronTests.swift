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

class CronTests: XCTestCase {
    static let eventBody = """
    {
        "Type":"Timer",
        "TriggerName":"EveryDay",
        "Time":"2019-02-21T11:49:00Z",
        "Message":"user define msg body"
    }
    """

    func testSimpleEventFromJSON() {
        let data = Self.eventBody.data(using: .utf8)!
        var event: Cron.Event?
        XCTAssertNoThrow(event = try JSONDecoder().decode(Cron.Event.self, from: data))

        XCTAssertEqual(event?.message, "user define msg body")
        XCTAssertEqual(event?.trigger, "EveryDay")
        XCTAssertEqual(event?.time.description, "2019-02-21 11:49:00 +0000")
    }

    func testEventTypeNotMatch() {
        let type = "time"
        let wrongJson = """
        {
            "Type":"\(type)",
            "TriggerName":"EveryDay",
            "Time":"2019-02-21T11:49:00Z",
            "Message":"user define msg body"
        }
        """
        let data = wrongJson.data(using: .utf8)!

        XCTAssertThrowsError(_ = try JSONDecoder().decode(Cron.Event.self, from: data)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Unexpected error: \(error)"); return
            }

            XCTAssertEqual(context.codingPath.compactMap { $0.stringValue }, ["Type"])
            XCTAssertEqual(context.debugDescription, #"Expected type to be "Timer", but `\#(type)` does not match"#)
            XCTAssertNil(context.underlyingError)
        }
    }

    func testEventDecodeAndEncode() {
        let data = Self.eventBody.data(using: .utf8)!
        let decoder = JSONDecoder()
        var event: Cron.Event?
        XCTAssertNoThrow(event = try decoder.decode(Cron.Event.self, from: data))

        var newEvent: Cron.Event?
        XCTAssertNoThrow(newEvent = try decoder.decode(Cron.Event.self, from: try JSONEncoder().encode(event)))

        XCTAssertEqual(event, newEvent)
    }
}
