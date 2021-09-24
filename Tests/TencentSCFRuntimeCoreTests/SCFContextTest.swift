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

import Logging
import NIOCore
import NIOPosix
@testable import TencentCloudCore
@testable import TencentSCFRuntimeCore
import XCTest

class SCFContextTest: XCTestCase {
    func testDefaultEnv() {
        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertEqual(context.memoryLimit, 128)
        XCTAssertEqual(context.timeLimit, .seconds(3))
        XCTAssertEqual(context.uin, "100000000001")
        XCTAssertEqual(context.appid, "1250000000")
        XCTAssertEqual(context.region, .ap_beijing)
        XCTAssertEqual(context.name, "my-swift-function")
        XCTAssertEqual(context.namespace, "default")
        XCTAssertEqual(context.version, .latest)
        XCTAssertNil(context.credential)
    }

    func testEnvUpdateWithDict() {
        let customEnvironment = [
            "TENCENTCLOUD_UIN": "100000000003",
            "TENCENTCLOUD_APPID": "1250000002",
            "TENCENTCLOUD_REGION": "ap-chengdu",
            "SCF_FUNCTIONNAME": "another-swift-function",
            "SCF_NAMESPACE": "custom",
            "SCF_FUNCTIONVERSION": "2",
            "TENCENTCLOUD_SECRETID": "SECRET_ID",
            "TENCENTCLOUD_SECRETKEY": "SECRET_KEY",
            "TENCENTCLOUD_SESSIONTOKEN": "SESSION_TOKEN",
        ]

        SCF.Env.update(with: customEnvironment)

        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertEqual(context.memoryLimit, 128)
        XCTAssertEqual(context.timeLimit, .seconds(3))
        XCTAssertEqual(context.uin, "100000000003")
        XCTAssertEqual(context.appid, "1250000002")
        XCTAssertEqual(context.region, .ap_chengdu)
        XCTAssertEqual(context.name, "another-swift-function")
        XCTAssertEqual(context.namespace, "custom")
        XCTAssertEqual(context.version, .version(2))
        XCTAssertNotNil(context.credential)
        XCTAssertEqual(context.credential?.secretId, "SECRET_ID")
        XCTAssertEqual(context.credential?.secretKey, "SECRET_KEY")
        XCTAssertEqual(context.credential?.sessionToken, "SESSION_TOKEN")

        SCF.Env.reset()
    }

    func testEnvSetDirectly() {
        let customEnvironment = [
            "TENCENTCLOUD_UIN": "100000000003",
            "TENCENTCLOUD_APPID": "1250000002",
            "TENCENTCLOUD_REGION": "ap-chengdu",
            "SCF_FUNCTIONNAME": "another-swift-function",
            "SCF_NAMESPACE": "custom",
            "SCF_FUNCTIONVERSION": "2",
            "TENCENTCLOUD_SECRETID": "SECRET_ID",
            "TENCENTCLOUD_SECRETKEY": "SECRET_KEY",
            "TENCENTCLOUD_SESSIONTOKEN": "SESSION_TOKEN",
        ]

        for (key, value) in customEnvironment {
            SCF.Env[key] = value
        }

        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertEqual(context.memoryLimit, 128)
        XCTAssertEqual(context.timeLimit, .seconds(3))
        XCTAssertEqual(context.uin, "100000000003")
        XCTAssertEqual(context.appid, "1250000002")
        XCTAssertEqual(context.region, .ap_chengdu)
        XCTAssertEqual(context.name, "another-swift-function")
        XCTAssertEqual(context.namespace, "custom")
        XCTAssertEqual(context.version, .version(2))
        XCTAssertNotNil(context.credential)
        XCTAssertEqual(context.credential?.secretId, "SECRET_ID")
        XCTAssertEqual(context.credential?.secretKey, "SECRET_KEY")
        XCTAssertEqual(context.credential?.sessionToken, "SESSION_TOKEN")

        SCF.Env.reset()
    }

    func testInvalidRegion() {
        SCF.Env["TENCENTCLOUD_REGION"] = "ap-ShangHai"

        let context = SCF.Context(requestID: UUID().uuidString.lowercased(),
                                  memoryLimit: 128,
                                  timeLimit: .seconds(3),
                                  logger: Logger(label: "test"),
                                  eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next(),
                                  allocator: ByteBufferAllocator())
        XCTAssertNil(context.region)

        SCF.Env.reset()
    }
}

#if os(Linux)
extension DispatchTimeInterval: Equatable {}
#endif
