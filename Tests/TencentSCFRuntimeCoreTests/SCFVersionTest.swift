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

import NIO
@testable import TencentSCFRuntimeCore
import XCTest

class SCFVersionTest: XCTestCase {
    func testSpecialVersionEqual() {
        assertVersionEqual(.latest, "$LATEST")
        assertVersionEqual(.null, "")
    }

    func testNumberedVersionEqual() {
        for i in 0 ..< 100 {
            assertVersionEqual(.version(i), "\(i)")
        }
    }

    func testStringVersionEqual() {
        let list = [
            "abcdE",
            "ac4sv",
            "44AA",
        ]
        for string in list {
            assertVersionEqual(.string(string), "\(string)")
        }
    }
}

func assertVersionEqual(_ versionEnum: SCF.Version, _ versionString: String) {
    XCTAssertEqual(versionEnum.description, versionString)
    XCTAssertEqual(SCF.Version(stringLiteral: versionString), versionEnum)
}
