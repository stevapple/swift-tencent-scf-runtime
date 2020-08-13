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

class CKafkaTests: XCTestCase {
    static let eventBody = """
    {
      "Records": [
        {
          "Ckafka": {
            "topic": "test-topic",
            "partition":1,
            "offset":36,
            "msgKey": "None",
            "msgBody": "Hello from Ckafka!"
          }
        },
        {
          "Ckafka": {
            "topic": "test-topic",
            "partition":1,
            "offset":37,
            "msgKey": "None",
            "msgBody": "Hello from Ckafka again!"
          }
        }
      ]
    }
    """

    func testSimpleEventFromJSON() {
        let data = Self.eventBody.data(using: .utf8)!
        var event: CKafka.Event?
        XCTAssertNoThrow(event = try JSONDecoder().decode(CKafka.Event.self, from: data))

        guard event?.records.count == 2 else {
            XCTFail("Expected to have two records")
            return
        }

        if let record = event?.records.first {
            XCTAssertEqual(record.topic, "test-topic")
            XCTAssertEqual(record.partition, 1)
            XCTAssertEqual(record.offset, 36)
            XCTAssertEqual(record.key, "None")
            XCTAssertEqual(record.body, "Hello from Ckafka!")
        } else {
            XCTFail("Unexpected error")
            return
        }

        if let record = event?.records.last {
            XCTAssertEqual(record.topic, "test-topic")
            XCTAssertEqual(record.partition, 1)
            XCTAssertEqual(record.offset, 37)
            XCTAssertEqual(record.key, "None")
            XCTAssertEqual(record.body, "Hello from Ckafka again!")
        } else {
            XCTFail("Unexpected error")
            return
        }
    }
}
