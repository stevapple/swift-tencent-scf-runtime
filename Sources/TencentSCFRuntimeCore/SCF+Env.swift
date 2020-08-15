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

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

// MARK: Env

extension SCF {
    /// Environment variables helper for SCF.
    public enum Env {
        #if DEBUG
        /// Preset overriding to simulate the SCF runtime context.
        private static let preset = [
            "TENCENTCLOUD_UIN": "100000000001",
            "TENCENTCLOUD_APPID": "1250000000",
            "TENCENTCLOUD_REGION": "ap-beijing",
            "SCF_FUNCTIONNAME": "my-swift-function",
            "SCF_NAMESPACE": "default",
            "SCF_FUNCTIONVERSION": "$LATEST",
        ]

        /// Custom environment variables overriding.
        private static var custom: [String: String] = [:]

        /// Batch override environment variables with `Dictionary`.
        public static func update(with dictionary: [String: String]) {
            Self.custom.merge(dictionary) { $1 }
        }

        /// Utility to read/override environment variables.
        public static subscript(_ key: String) -> String? {
            get {
                if let value = Self.custom[key] {
                    return value
                } else if let value = getenv(key) {
                    return String(cString: value)
                } else if let value = Self.preset[key] {
                    return value
                } else {
                    return nil
                }
            }
            set(newValue) {
                Self.custom[key] = newValue
            }
        }

        // for testing and internal use
        internal static func reset() {
            Self.custom = [:]
        }
        #else
        /// Utility to read environment variables.
        public static subscript(_ key: String) -> String? {
            guard let value = getenv(key) else {
                return nil
            }
            return String(cString: value)
        }
        #endif
    }
}
