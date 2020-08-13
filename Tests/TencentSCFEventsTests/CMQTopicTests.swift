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

class CMQTopicTests: XCTestCase {
    static let eventBody = """
    {
      "Records": [
        {
          "CMQ": {
            "type": "topic",
            "topicOwner":12014223,
            "topicName": "testtopic",
            "subscriptionName":"xxxxxx",
            "publishTime": "1970-01-01T00:00:00.000Z",
            "msgId": "123345346",
            "requestId":"123345346",
            "msgBody": "Hello from CMQ!",
            "msgTag": "tag1,tag2"
          }
        }
      ]
    }
    """

    func testSimpleEventFromJSON() {
        let data = Self.eventBody.data(using: .utf8)!
        var event: CMQ.Topic.Event?
        XCTAssertNoThrow(event = try JSONDecoder().decode(CMQ.Topic.Event.self, from: data))

        guard let record = event?.records.first else {
            XCTFail("Expected to have one record")
            return
        }

        XCTAssertEqual(record.topicName, "testtopic")
        XCTAssertEqual(record.topicOwner, 12_014_223)
        XCTAssertEqual(record.subscriptionName, "xxxxxx")
        XCTAssertEqual(record.message.id, "123345346")
        XCTAssertEqual(record.message.body, "Hello from CMQ!")
        XCTAssertEqual(record.message.requestId, "123345346")
        XCTAssertEqual(record.message.tags, ["tag1", "tag2"])
        XCTAssertEqual(record.message.publishTime.description, "1970-01-01 00:00:00 +0000")
    }
}
