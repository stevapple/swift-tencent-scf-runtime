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

extension COS.Event.Record: Decodable {
    enum CodingKeys: String, CodingKey {
        case event
        case cos
    }

    enum EventCodingKeys: String, CodingKey {
        case eventName
        case eventVersion
        case eventTime
        case eventSource
        case requestParameters
        case eventQueue
        case reservedInfo
        case requestId = "reqid"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cos = try container.decode(COS.Entity.self, forKey: .cos)

        let eventContainer = try container.nestedContainer(keyedBy: EventCodingKeys.self, forKey: .event)
        eventName = try eventContainer.decode(String.self, forKey: .eventName)
        eventVersion = try eventContainer.decode(String.self, forKey: .eventVersion)
        eventSource = try eventContainer.decode(String.self, forKey: .eventSource)
        eventQueue = try eventContainer.decode(String.self, forKey: .eventQueue)
        reservedInfo = try eventContainer.decode(String.self, forKey: .reservedInfo)
        requestId = try eventContainer.decode(UInt64.self, forKey: .requestId)
        requestParameters = try eventContainer.decode(COS.RequestParameters.self, forKey: .requestParameters)
        eventTime = try eventContainer.decode(Date.self, forKey: .eventTime, using: DateCoding.UnixTimestamp.self)
    }
}
