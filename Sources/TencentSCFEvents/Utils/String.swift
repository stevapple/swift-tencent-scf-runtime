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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

internal extension String {
    func jsonEncoded() -> String {
        var bytes = [UInt8]()
        let stringBytes = self.utf8
        var startCopyIndex = stringBytes.startIndex
        var nextIndex = startCopyIndex

        while nextIndex != stringBytes.endIndex {
            switch stringBytes[nextIndex] {
            case 0 ..< 32, UInt8(ascii: "\""), UInt8(ascii: "\\"):
                // All Unicode characters may be placed within the
                // quotation marks, except for the characters that MUST be escaped:
                // quotation mark, reverse solidus, and the control characters (U+0000
                // through U+001F).
                // https://tools.ietf.org/html/rfc7159#section-7
                // copy the current range over
                bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
                bytes.append(UInt8(ascii: "\\"))
                bytes.append(stringBytes[nextIndex])

                nextIndex = stringBytes.index(after: nextIndex)
                startCopyIndex = nextIndex
            default:
                nextIndex = stringBytes.index(after: nextIndex)
            }
        }

        return String(bytes: bytes, encoding: .utf8)!
    }
}
