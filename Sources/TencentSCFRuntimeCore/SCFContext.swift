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

import Dispatch
import Logging
import NIO
import TencentCloudCore

// MARK: - InitializationContext

extension SCF {
    /// SCF runtime initialization context.
    /// The `SCF.runtime` generates and passes the `InitializationContext` to the SCF factory as an argument.
    public final class InitializationContext {
        /// `Logger` to log with.
        ///
        /// - Note: The `LogLevel` can be configured using the `LOG_LEVEL` environment variable.
        public let logger: Logger

        /// The `EventLoop` the SCF function is executed on. Use this to schedule work with.
        ///
        /// - Note: The `EventLoop` is shared with the SCF Runtime Engine and should be handled with extra care.
        ///         Most importantly the `EventLoop` must never be blocked.
        public let eventLoop: EventLoop

        /// `ByteBufferAllocator` to allocate `ByteBuffer`.
        public let allocator: ByteBufferAllocator

        internal init(logger: Logger, eventLoop: EventLoop, allocator: ByteBufferAllocator) {
            self.eventLoop = eventLoop
            self.logger = logger
            self.allocator = allocator
        }
    }
}

// MARK: - Context

extension SCF {
    /// SCF runtime context.
    /// The SCF runtime generates and passes the `Context` to the SCF handler as an argument.
    public final class Context: CustomDebugStringConvertible {
        /// The request ID, which identifies the request that triggered the function invocation.
        public let requestID: String

        /// The memory limit of the cloud function in MB.
        public let memoryLimit: UInt

        /// The time limit of the cloud function event in ms.
        public let timeLimit: DispatchTimeInterval

        /// The timestamp that the function times out.
        public let deadline: DispatchWallTime

        /// The UIN of cloud function actor.
        public var uin: String {
            SCF.Env["TENCENTCLOUD_UIN"] ?? ""
        }

        /// The APPID that the cloud function belongs to.
        public var appid: String {
            SCF.Env["TENCENTCLOUD_APPID"] ?? ""
        }

        /// The Tencent Cloud region that the cloud function is in.
        public var region: TencentCloud.Region? {
            TencentCloud.Region(rawValue: SCF.Env["TENCENTCLOUD_REGION"] ?? "")
        }

        /// The name of the cloud function.
        public var name: String {
            SCF.Env["SCF_FUNCTIONNAME"] ?? ""
        }

        /// The namespace of the cloud function.
        public var namespace: String {
            SCF.Env["SCF_NAMESPACE"] ?? ""
        }

        /// The version of the cloud function.
        public var version: Version {
            .init(stringLiteral: SCF.Env["SCF_FUNCTIONVERSION"] ?? "")
        }

        /// The role credential from SCF environment.
        public var credential: TencentCloud.Credential? {
            if let secretId = SCF.Env["TENCENTCLOUD_SECRETID"],
               let secretKey = SCF.Env["TENCENTCLOUD_SECRETKEY"] {
                return TencentCloud.Credential(secretId: secretId,
                                               secretKey: secretKey,
                                               sessionToken: SCF.Env["TENCENTCLOUD_SESSIONTOKEN"])
            } else {
                return nil
            }
        }

        /// `Logger` to log with.
        ///
        /// - Note: The `LogLevel` can be configured using the `LOG_LEVEL` environment variable.
        public let logger: Logger

        /// The `EventLoop` the SCF function is executed on. Use this to schedule work with.
        /// This is useful when implementing the `EventLoopSCFHandler` protocol.
        ///
        /// - Note: The `EventLoop` is shared with the SCF Runtime Engine and should be handled with extra care.
        ///         Most importantly the `EventLoop` must never be blocked.
        public let eventLoop: EventLoop

        /// `ByteBufferAllocator` to allocate `ByteBuffer`.
        /// This is useful when implementing `EventLoopSCFHandler`.
        public let allocator: ByteBufferAllocator

        internal init(requestID: String,
                      memoryLimit: UInt,
                      timeLimit: DispatchTimeInterval,
                      logger: Logger,
                      eventLoop: EventLoop,
                      allocator: ByteBufferAllocator)
        {
            self.requestID = requestID
            self.memoryLimit = memoryLimit
            self.deadline = DispatchWallTime.now() + timeLimit
            self.timeLimit = timeLimit
            // utilities
            self.eventLoop = eventLoop
            self.allocator = allocator
            // Mutate logger with context.
            var logger = logger
            logger[metadataKey: "scfRequestID"] = .string(requestID)
            self.logger = logger
        }

        public func getRemainingTime() -> TimeAmount {
            let deadline = self.deadline.millisSinceEpoch
            let now = DispatchWallTime.now().millisSinceEpoch

            let remaining = deadline - now
            return .milliseconds(remaining)
        }

        public var debugDescription: String {
            "\(Self.self)(requestID: \(self.requestID), memoryLimit: \(self.memoryLimit)MB, timeLimit: \(self.timeLimit), deadline: \(self.deadline)"
        }
    }

    public enum Version: ExpressibleByStringLiteral, CustomStringConvertible, Equatable {
        public typealias StringLiteralType = String
        case latest
        case null
        case version(Int)
        case string(String)

        public init(stringLiteral value: String) {
            if value == "$LATEST" {
                self = .latest
            } else if value == "" {
                self = .null
            } else if let version = Int(value) {
                self = .version(version)
            } else {
                self = .string(value)
            }
        }

        public var description: String {
            switch self {
            case .latest:
                return "$LATEST"
            case .null:
                return ""
            case .version(let no):
                return "\(no)"
            case .string(let desc):
                return desc
            }
        }
    }
}

// MARK: - ShutdownContext

extension SCF {
    /// SCF runtime shutdown context.
    /// The SCF runtime generates and passes the `ShutdownContext` to the SCF handler as an argument.
    public final class ShutdownContext {
        /// `Logger` to log with
        ///
        /// - Note: The `LogLevel` can be configured using the `LOG_LEVEL` environment variable.
        public let logger: Logger

        /// The `EventLoop` the cloud function is executed on. Use this to schedule work with.
        ///
        /// - Note: The `EventLoop` is shared with the SCF Runtime Engine and should be handled with extra care.
        ///         Most importantly the `EventLoop` must never be blocked.
        public let eventLoop: EventLoop

        internal init(logger: Logger, eventLoop: EventLoop) {
            self.eventLoop = eventLoop
            self.logger = logger
        }
    }
}
