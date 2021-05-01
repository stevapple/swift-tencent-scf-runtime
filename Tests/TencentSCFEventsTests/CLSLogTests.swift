//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2021 stevapple and the SwiftTencentSCFRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Gzip
@testable import TencentSCFEvents
import XCTest

class CLSLogTests: XCTestCase {
    static let realBody = """
    {
      "topic_id": "xxxx-xx-xx-xx-yyyyyyyy",
      "topic_name": "testname",
      "records": [{
        "timestamp": "1605578090000020",
        "content": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }, {
        "timestamp": "1605578090000040",
        "content": "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
      }]
    }
    """

    static var eventBody: String {
        let data = try! realBody.data(using: .utf8)!.gzipped().base64EncodedString()
        return """
        {
          "clslogs": {
            "data": "\(data)"
          }
        }
        """
    }

    func testSimpleEventFromJSON() {
        let data = Self.eventBody.data(using: .utf8)!
        var event: CLS.Logs?
        XCTAssertNoThrow(event = try JSONDecoder().decode(CLS.Logs.self, from: data))

        XCTAssertEqual(event?.topicId, "xxxx-xx-xx-xx-yyyyyyyy")
        XCTAssertEqual(event?.topicName, "testname")
        guard let record1 = event?.records.first,
              let record2 = event?.records.last else {
            XCTFail("Expected to have 2 records")
            return
        }

        XCTAssertEqual(record1.content, "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        XCTAssertEqual(record2.content, "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        XCTAssertEqual(record1.timestamp, 1_605_578_090_000_020)
        XCTAssertEqual(record2.timestamp, 1_605_578_090_000_040)
        XCTAssertEqual(record2.date.timeIntervalSince(record1.date), 0.02, accuracy: 0.0001)
    }
}
