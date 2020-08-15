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

// List all available regions using tccli:
//   $ tccli cvm DescribeRegions

/// Enumeration of the Tencent Cloud regions.
public enum TencentCloud {
    public struct Region: RawRepresentable, CustomStringConvertible, Equatable, Hashable {
        public typealias RawValue = String

        public let rawValue: String

        public init?(rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String {
            self.rawValue
        }

        static var regular: [Self] = [
            .ap_bangkok,
            .ap_beijing,
            .ap_chengdu,
            .ap_chongqing,
            .ap_guangzhou,
            .ap_guangzhou_open,
            .ap_hongkong,
            .ap_numbai,
            .ap_nanjing,
            .ap_seoul,
            .ap_shanghai,
            .ap_singapore,
            .ap_tokyo,
            .eu_frankfurt,
            .eu_moscow,
            .na_ashburn,
            .na_siliconvalley,
            .na_toronto,
        ]

        static var financial: [Self] = [
            .ap_shanghai_fsi,
            .ap_shenzhen_fsi,
        ]

        static var mainland: [Self] = [
            .ap_beijing,
            .ap_chengdu,
            .ap_chongqing,
            .ap_guangzhou,
            .ap_guangzhou_open,
            .ap_nanjing,
            .ap_shanghai,
            .ap_shanghai_fsi,
            .ap_shenzhen_fsi,
        ]

        static var overseas: [Self] = [
            .ap_bangkok,
            .ap_hongkong,
            .ap_numbai,
            .ap_seoul,
            .ap_singapore,
            .ap_tokyo,
            .eu_frankfurt,
            .eu_moscow,
            .na_ashburn,
            .na_siliconvalley,
            .na_toronto,
        ]

        public static var ap_bangkok: Self { Region(rawValue: "ap-bangkok")! } // Thailand
        public static var ap_beijing: Self { Region(rawValue: "ap-beijing")! } // Beijing, China
        public static var ap_chengdu: Self { Region(rawValue: "ap-chengdu")! } // Sichuan, China
        public static var ap_chongqing: Self { Region(rawValue: "ap-chongqing")! } // Chongqing, China
        public static var ap_guangzhou: Self { Region(rawValue: "ap-guangzhou")! } // Guangdong, China
        public static var ap_guangzhou_open: Self { Region(rawValue: "ap-guangzhou-open")! } // Guangdong, China (Open)
        public static var ap_hongkong: Self { Region(rawValue: "ap-hongkong")! } // Hong Kong, China
        public static var ap_numbai: Self { Region(rawValue: "ap-numbai")! } // India
        public static var ap_nanjing: Self { Region(rawValue: "ap-nanjing")! } // Jiangsu, China
        public static var ap_seoul: Self { Region(rawValue: "ap-seoul")! } // South Korea
        public static var ap_shanghai: Self { Region(rawValue: "ap-shanghai")! } // Shanghai, China
        public static var ap_shanghai_fsi: Self { Region(rawValue: "ap-shanghai-fsi")! } // Shanghai, China (Financial)
        public static var ap_shenzhen_fsi: Self { Region(rawValue: "ap-shenzhen-fsi")! } // Guangdong, China (Financial)
        public static var ap_singapore: Self { Region(rawValue: "ap-singapore")! } // Singapore
        public static var ap_tokyo: Self { Region(rawValue: "ap-tokyo")! } // Japan

        public static var eu_frankfurt: Self { Region(rawValue: "eu-frankfurt")! } // German
        public static var eu_moscow: Self { Region(rawValue: "eu-moscow")! } // Russia
        public static var na_ashburn: Self { Region(rawValue: "na-ashburn")! } // Virginia, US
        public static var na_siliconvalley: Self { Region(rawValue: "na-siliconvalley")! } // California, US
        public static var na_toronto: Self { Region(rawValue: "na-toronto")! } // Canada
    }
}

extension TencentCloud.Region: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let region = try container.decode(String.self)
        self.init(rawValue: region)!
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
