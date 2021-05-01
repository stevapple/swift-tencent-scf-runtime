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

import struct Foundation.Data

// https://intl.cloud.tencent.com/document/product/583/38845

extension CLS {
    struct _Logs: Decodable {
        let topicId: String
        let topicName: String
        let records: [CLS.Record]

        enum CodingKeys: String, CodingKey {
            case topicId = "topic_id"
            case topicName = "topic_name"
            case records
        }
    }

    struct Raw: Decodable {
        let data: Data

        enum WrappingCodingKeys: String, CodingKey {
            case logs = "clslogs"
        }

        enum CodingKeys: String, CodingKey {
            case data
        }

        public init(from decoder: Decoder) throws {
            let wrapperContainer = try decoder.container(keyedBy: WrappingCodingKeys.self)
            let container = try wrapperContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .logs)
            let rawString = try container.decode(String.self, forKey: .data)
            guard let data = Data(base64Encoded: rawString) else {
                throw DecodingError.dataCorruptedError(forKey: .data, in: container, debugDescription: "Base64 decoding error")
            }
            self.data = data
        }
    }
}
