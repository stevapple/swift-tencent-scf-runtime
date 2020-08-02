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

class DateWrapperTests: XCTestCase {
    func testISO8601DateCodingWrapperSuccess() {
        struct TestEvent: Decodable {
            @ISO8601DateCoding
            var date: Date
        }

        let json = #"{"date":"2020-03-26T16:53:05Z"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date, Date(timeIntervalSince1970: 1_585_241_585))
    }

    func testISO8601DateCodingWrapperFailure() {
        struct TestEvent: Decodable {
            @ISO8601DateCoding
            var date: Date
        }

        let date = "2020-03-26T16:53:05" // missing Z at end
        let json = #"{"date":"\#(date)"}"#
        XCTAssertThrowsError(_ = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Unexpected error: \(error)"); return
            }

            XCTAssertEqual(context.codingPath.compactMap { $0.stringValue }, ["date"])
            XCTAssertEqual(context.debugDescription, "Expected date to be in iso8601 date format, but `\(date)` does not forfill format")
            XCTAssertNil(context.underlyingError)
        }
    }

    func testISO8601DateCodingOptionalWrapperSuccessWithValue() {
        struct TestEvent: Decodable {
            @ISO8601DateCodingOptional
            var date: Date?
        }

        let json = #"{"date":"2020-03-26T16:53:05Z"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date, Date(timeIntervalSince1970: 1_585_241_585))
    }

    func testISO8601DateCodingOptionalWrapperSuccessWithNil() {
        struct TestEvent: Decodable {
            @ISO8601DateCodingOptional
            var date: Date?
        }

        let json = "{}"
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertNil(event?.date)
    }

    func testISO8601DateWithFractionalSecondsCodingWrapperSuccess() {
        struct TestEvent: Decodable {
            @ISO8601DateWithFractionalSecondsCoding
            var date: Date
        }

        let json = #"{"date":"2020-03-26T16:53:05.123Z"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date, Date(timeIntervalSince1970: 1_585_241_585.123))
    }

    func testISO8601DateWithFractionalSecondsCodingWrapperFailure() {
        struct TestEvent: Decodable {
            @ISO8601DateWithFractionalSecondsCoding
            var date: Date
        }

        let date = "2020-03-26T16:53:05Z" // missing fractional seconds
        let json = #"{"date":"\#(date)"}"#
        XCTAssertThrowsError(_ = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Unexpected error: \(error)"); return
            }

            XCTAssertEqual(context.codingPath.compactMap { $0.stringValue }, ["date"])
            XCTAssertEqual(context.debugDescription, "Expected date to be in iso8601 date format with fractional seconds, but `\(date)` does not forfill format")
            XCTAssertNil(context.underlyingError)
        }
    }

    func testISO8601DateWithFractionalSecondsCodingOptionalWrapperSuccessWithValue() {
        struct TestEvent: Decodable {
            @ISO8601DateWithFractionalSecondsCodingOptional
            var date: Date?
        }

        let json = #"{"date":"2020-03-26T16:53:05.123Z"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date, Date(timeIntervalSince1970: 1_585_241_585.123))
    }

    func testISO8601DateWithFractionalSecondsCodingOptionalWrapperSuccessWithNil() {
        struct TestEvent: Decodable {
            @ISO8601DateWithFractionalSecondsCodingOptional
            var date: Date?
        }

        let json = "{}"
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertNil(event?.date)
    }

    func testRFC5322DateTimeCodingWrapperSuccess() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCoding
            var date: Date
        }

        let json = #"{"date":"Thu, 5 Apr 2012 23:47:37 +0200"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date.description, "2012-04-05 21:47:37 +0000")
    }

    func testRFC5322DateTimeCodingWrapperWithExtraTimeZoneSuccess() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCoding
            var date: Date
        }

        let json = #"{"date":"Fri, 26 Jun 2020 03:04:03 -0500 (CDT)"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date.description, "2020-06-26 08:04:03 +0000")
    }

    func testRFC5322DateTimeCodingWrapperWithAlphabeticTimeZoneSuccess() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCoding
            var date: Date
        }

        let json = #"{"date":"Fri, 26 Jun 2020 03:04:03 CDT"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date.description, "2020-06-26 08:04:03 +0000")
    }

    func testRFC5322DateTimeCodingWrapperFailure() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCoding
            var date: Date
        }

        let date = "Thu, 5 Apr 2012 23:47 +0200" // missing seconds
        let json = #"{"date":"\#(date)"}"#
        XCTAssertThrowsError(_ = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Unexpected error: \(error)"); return
            }

            XCTAssertEqual(context.codingPath.compactMap { $0.stringValue }, ["date"])
            XCTAssertEqual(context.debugDescription, "Expected date to be in RFC5322 date-time format with fractional seconds, but `\(date)` does not forfill format")
            XCTAssertNil(context.underlyingError)
        }
    }

    func testRFC5322DateTimeCodingOptionalWrapperSuccessWithValue() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCodingOptional
            var date: Date?
        }

        let json = #"{"date":"Thu, 5 Apr 2012 23:47:37 +0200"}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date?.description, "2012-04-05 21:47:37 +0000")
    }

    func testRFC5322DateTimeCodingOptionalWrapperSuccessWithNil() {
        struct TestEvent: Decodable {
            @RFC5322DateTimeCodingOptional
            var date: Date?
        }

        let json = "{}"
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertNil(event?.date)
    }

    func testUnixTimestampCodingWrapperSuccess() {
        struct TestEvent: Decodable {
            @UnixTimestampCoding
            var date: Date
        }

        let json = #"{"date":1596301934}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date.description, "2020-08-01 17:12:14 +0000")
    }

    func testUnixTimestampCodingWrapperFailure() {
        struct TestEvent: Decodable {
            @UnixTimestampCoding
            var date: Date
        }
        let date = -15963
        let json = #"{"date":\#(date)}"# // Negative value
        XCTAssertThrowsError(_ = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Unexpected error: \(error)"); return
            }

            XCTAssertEqual(context.codingPath.compactMap { $0.stringValue }, ["date"])
            XCTAssertEqual(context.debugDescription, "Parsed JSON number <\(date)> does not fit in UInt.")
            XCTAssertNil(context.underlyingError)
        }
    }

    func testUnixTimestampCodingOptionalWrapperSuccessWithValue() {
        struct TestEvent: Decodable {
            @UnixTimestampCodingOptional
            var date: Date?
        }

        let json = #"{"date":1596301934}"#
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertEqual(event?.date?.description, "2020-08-01 17:12:14 +0000")
    }

    func testUnixTimestampCodingOptionalWrapperSuccessWithNil() {
        struct TestEvent: Decodable {
            @UnixTimestampCodingOptional
            var date: Date?
        }

        let json = "{}"
        var event: TestEvent?
        XCTAssertNoThrow(event = try JSONDecoder().decode(TestEvent.self, from: json.data(using: .utf8)!))

        XCTAssertNil(event?.date)
    }
}
