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
// Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Dispatch
import NIO

/// Tencent SCF Custom Runtime API endpoints.
internal enum Endpoint {
    static let getNextInvocation = "/runtime/invocation/next"
    static let postResponse = "/runtime/invocation/response"
    static let postError = "/runtime/invocation/error"
    static let postInitReady = "/runtime/init/ready"
}

/// Tencent SCF HTTP Headers, used to populate the `SCF.Context` object.
internal enum SCFHeaders {
    static let requestID = "request_id"
    static let memoryLimit = "memory_limit_in_mb"
    static let timeLimit = "time_limit_in_ms"
}

/// Helper function to trap signals.
internal func trap(signal sig: Signal, handler: @escaping (Signal) -> Void) -> DispatchSourceSignal {
    let signalSource = DispatchSource.makeSignalSource(signal: sig.rawValue, queue: DispatchQueue.global())
    signal(sig.rawValue, SIG_IGN)
    signalSource.setEventHandler(handler: {
        signalSource.cancel()
        handler(sig)
    })
    signalSource.resume()
    return signalSource
}

internal enum Signal: Int32 {
    case HUP = 1
    case INT = 2
    case QUIT = 3
    case ABRT = 6
    case KILL = 9
    case ALRM = 14
    case TERM = 15
}

extension DispatchWallTime {
    internal init(millisSinceEpoch: Int64) {
        let nanoSinceEpoch = UInt64(millisSinceEpoch) * 1_000_000
        let seconds = UInt64(nanoSinceEpoch / 1_000_000_000)
        let nanoseconds = nanoSinceEpoch - (seconds * 1_000_000_000)
        self.init(timespec: timespec(tv_sec: Int(seconds), tv_nsec: Int(nanoseconds)))
    }

    internal var millisSinceEpoch: Int64 {
        Int64(bitPattern: self.rawValue) / -1_000_000
    }
}

extension String {
    func encodeAsJSONString(into bytes: inout [UInt8]) {
        bytes.append(UInt8(ascii: "\""))
        let stringBytes = self.utf8
        var startCopyIndex = stringBytes.startIndex
        var nextIndex = startCopyIndex

        while nextIndex != stringBytes.endIndex {
            switch stringBytes[nextIndex] {
            case 0 ..< 32, UInt8(ascii: "\""), UInt8(ascii: "\\"):
                // All Unicode characters may be placed within the quotation marks, except for the
                // characters that MUST be escaped:
                // quotation mark, reverse solidus, and the control characters (U+0000 through
                // U+001F).
                // https://tools.ietf.org/html/rfc7159#section-7

                // Copy the current range over.
                bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
                bytes.append(UInt8(ascii: "\\"))
                bytes.append(stringBytes[nextIndex])

                nextIndex = stringBytes.index(after: nextIndex)
                startCopyIndex = nextIndex
            default:
                nextIndex = stringBytes.index(after: nextIndex)
            }
        }

        // Copy everything that hasn't been copied yet.
        bytes.append(contentsOf: stringBytes[startCopyIndex ..< nextIndex])
        bytes.append(UInt8(ascii: "\""))
    }
}
