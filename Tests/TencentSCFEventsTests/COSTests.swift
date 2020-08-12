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

@testable import TencentSCFEvents
import XCTest

class COSTests: XCTestCase {
    static let eventBody = """
    {
        "Records": [{
            "cos": {
                "cosSchemaVersion": "1.0",
                "cosObject": {
                    "url": "http://testpic-1253970026.cos.ap-chengdu.myqcloud.com/testfile",
                    "meta": {
                        "x-cos-request-id": "NWMxOWY4MGFfMjViMjU4NjRfMTUyMVxxxxxxxxx=",
                        "Content-Type": "",
                        "x-cos-meta-mykey": "myvalue",
                        "Expire-Time": "Thu, 5 Apr 2012 23:47:37 +0200"
                    },
                    "vid": "",
                    "key": "/1253970026/testpic/testfile",
                    "size": 1029
                },
                "cosBucket": {
                    "region": "cd",
                    "name": "testpic",
                    "appid": "1253970026"
                },
                "cosNotificationId": "unknown"
            },
            "event": {
                "eventName": "cos:ObjectCreated:CompleteMultipartUpload",
                "eventVersion": "1.0",
                "eventTime": 1545205770,
                "eventSource": "qcs::cos",
                "requestParameters": {
                    "requestSourceIP": "192.168.15.101",
                    "requestHeaders": {
                        "Authorization": "q-sign-algorithm=sha1&q-ak=xxxxxxxxxxxxxx&q-sign-time=1545205709;1545215769&q-key-time=1545205709;1545215769&q-header-list=host;x-cos-storage-class&q-url-param-list=&q-signature=xxxxxxxxxxxxxxx"
                    }
                },
                "eventQueue": "qcs:0:scf:cd:appid/1253970026:default.printevent.$LATEST",
                "reservedInfo": "",
                "reqid": 179398952
            }
        }]
    }
    """

    func testSimpleEventFromJSON() {
        let data = Self.eventBody.data(using: .utf8)!
        var event: COS.Event?
        XCTAssertNoThrow(event = try JSONDecoder().decode(COS.Event.self, from: data))

        guard let record = event?.records.first else {
            XCTFail("Expected to have one record")
            return
        }

        XCTAssertEqual(record.cos.schemaVersion, "1.0")
        XCTAssertEqual(record.cos.notificationId, "unknown")
        XCTAssertEqual(record.cos.bucket.region, "cd")
        XCTAssertEqual(record.cos.bucket.name, "testpic")
        XCTAssertEqual(record.cos.bucket.appid, "1253970026")
        XCTAssertEqual(record.cos.object.fullKey, "/1253970026/testpic/testfile")
        XCTAssertEqual(record.cos.object.key, "testfile")
        XCTAssertEqual(record.cos.object.size, 1029)
        XCTAssertEqual(record.cos.object.vid, "")
        XCTAssertEqual(record.cos.object.contentType, "")
        XCTAssertNil(record.cos.object.cacheControl)
        XCTAssertNil(record.cos.object.contentDisposition)
        XCTAssertNil(record.cos.object.contentEncoding)
        XCTAssertEqual(record.cos.object.expireTime?.description, "2012-04-05 21:47:37 +0000")
        XCTAssertEqual(record.cos.object.customMeta, ["mykey": "myvalue"])

        XCTAssertEqual(record.eventName, "cos:ObjectCreated:CompleteMultipartUpload")
        XCTAssertEqual(record.eventVersion, "1.0")
        XCTAssertEqual(record.eventSource, "qcs::cos")
        XCTAssertEqual(record.eventTime, Date(timeIntervalSince1970: 1_545_205_770))
        XCTAssertEqual(record.requestParameters.sourceIP, "192.168.15.101")
        XCTAssertEqual(record.requestParameters.headers, ["Authorization": "q-sign-algorithm=sha1&q-ak=xxxxxxxxxxxxxx&q-sign-time=1545205709;1545215769&q-key-time=1545205709;1545215769&q-header-list=host;x-cos-storage-class&q-url-param-list=&q-signature=xxxxxxxxxxxxxxx"])
        XCTAssertEqual(record.requestId, 179_398_952)
        XCTAssertEqual(record.reservedInfo, "")
    }

    func testEventDecodeAndEncode() {
        let data = Self.eventBody.data(using: .utf8)!
        let decoder = JSONDecoder()
        var event: COS.Event?
        XCTAssertNoThrow(event = try decoder.decode(COS.Event.self, from: data))

        var newEvent: COS.Event?
        XCTAssertNoThrow(newEvent = try decoder.decode(COS.Event.self, from: try JSONEncoder().encode(event)))

        XCTAssertEqual(event, newEvent)
    }
}
