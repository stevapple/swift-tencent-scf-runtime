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

/// A `struct` representing a Tencent Cloud credential.
extension TencentCloud {
    public struct Credential {
        let secretId: String
        let secretKey: String
        let sessionToken: String?

        enum CodingKeys: String, CodingKey {
            case secretId = "SecretId"
            case secretKey = "SecretKey"
            case sessionToken = "SessionToken"
        }

        public init(secretId: String,
                    secretKey: String,
                    sessionToken: String? = nil)
        {
            self.secretId = secretId
            self.secretKey = secretKey
            self.sessionToken = sessionToken
        }
    }
}
