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

import struct Foundation.Date
import struct Foundation.URL

// https://cloud.tencent.com/document/product/583/9707

public enum COS {
    public struct Event: Codable, Equatable {
        public struct Record: Equatable {
            public let cos: Entity

            public let eventName: String
            public let eventVersion: String
            public let eventTime: Date
            public let eventSource: String
            public let requestParameters: RequestParameters
            public let eventQueue: String
            public let reservedInfo: String
            public let requestId: UInt64
        }

        public let records: [Record]

        public enum CodingKeys: String, CodingKey {
            case records = "Records"
        }
    }

    public struct RequestParameters: Codable, Equatable {
        public let sourceIP: String
        public let headers: [String: String]

        enum CodingKeys: String, CodingKey {
            case sourceIP = "requestSourceIP"
            case headers = "requestHeaders"
        }
    }

    public struct Entity: Codable, Equatable {
        public let notificationId: String
        public let schemaVersion: String
        public let bucket: Bucket
        public let object: Object

        enum CodingKeys: String, CodingKey {
            case notificationId = "cosNotificationId"
            case schemaVersion = "cosSchemaVersion"
            case bucket = "cosBucket"
            case object = "cosObject"
        }
    }

    public struct Bucket: Codable, Equatable {
        public let region: String
        public let name: String
        public let appid: String
    }

    public struct Object: Equatable {
        public let url: URL
        public let key: String
        public let vid: String
        public let size: UInt64

        public let contentType: String?
        public let cacheControl: String?
        public let contentDisposition: String?
        public let contentEncoding: String?
        public let requestId: String?

        public let expireTime: Date?
        public let customMeta: [String: String]
    }
}
