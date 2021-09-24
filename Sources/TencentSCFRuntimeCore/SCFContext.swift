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
import NIOCore
import TencentCloudCore

// MARK: - InitializationContext

extension SCF {
    /// SCF runtime initialization context.
    /// The `SCF.runtime` generates and passes the `InitializationContext` to the SCF factory as an argument.
    public struct InitializationContext {
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

        /// This interface is not part of the public API and must not be used by adopters.
        /// This API is not part of semver versioning.
        public static func __forTestsOnly(
            logger: Logger,
            eventLoop: EventLoop
        ) -> InitializationContext {
            InitializationContext(
                logger: logger,
                eventLoop: eventLoop,
                allocator: ByteBufferAllocator()
            )
        }
    }
}

// MARK: - Context

extension SCF {
    /// SCF runtime context.
    /// The SCF runtime generates and passes the `Context` to the SCF handler as an argument.
    public struct Context: CustomDebugStringConvertible {
        final class _Storage {
            var requestID: String
            var memoryLimit: UInt
            var timeLimit: DispatchTimeInterval
            var deadline: DispatchWallTime
            var logger: Logger
            var eventLoop: EventLoop
            var allocator: ByteBufferAllocator

            init(
                requestID: String,
                memoryLimit: UInt,
                timeLimit: DispatchTimeInterval,
                logger: Logger,
                eventLoop: EventLoop,
                allocator: ByteBufferAllocator
            ) {
                self.requestID = requestID
                self.memoryLimit = memoryLimit
                self.timeLimit = timeLimit
                self.deadline = .now() + timeLimit
                self.logger = logger
                self.eventLoop = eventLoop
                self.allocator = allocator
            }
        }

        private var storage: _Storage

        /// The request ID, which identifies the request that triggered the function invocation.
        public var requestID: String {
            self.storage.requestID
        }

        /// The memory limit of the cloud function in MB.
        public var memoryLimit: UInt {
            self.storage.memoryLimit
        }

        /// The time limit of the cloud function event in ms.
        public var timeLimit: DispatchTimeInterval {
            self.storage.timeLimit
        }

        /// The timestamp that the function times out.
        public var deadline: DispatchWallTime {
            self.storage.deadline
        }

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
        public var logger: Logger {
            self.storage.logger
        }

        /// The `EventLoop` the SCF function is executed on. Use this to schedule work with.
        /// This is useful when implementing the `EventLoopSCFHandler` protocol.
        ///
        /// - Note: The `EventLoop` is shared with the SCF Runtime Engine and should be handled with extra care.
        ///         Most importantly the `EventLoop` must never be blocked.
        public var eventLoop: EventLoop {
            self.storage.eventLoop
        }

        /// `ByteBufferAllocator` to allocate `ByteBuffer`.
        /// This is useful when implementing `EventLoopSCFHandler`.
        public var allocator: ByteBufferAllocator {
            self.storage.allocator
        }

        internal init(requestID: String,
                      memoryLimit: UInt,
                      timeLimit: DispatchTimeInterval,
                      logger: Logger,
                      eventLoop: EventLoop,
                      allocator: ByteBufferAllocator)
        {
            self.storage = _Storage(
                requestID: requestID,
                memoryLimit: memoryLimit,
                timeLimit: timeLimit,
                logger: logger,
                eventLoop: eventLoop,
                allocator: allocator
            )
            self.storage.logger[metadataKey: "scfRequestID"] = .string(requestID)
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

        /// This interface is not part of the public API and must not be used by adopters.
        /// This API is not part of semver versioning.
        public static func __forTestsOnly(
            requestID: String,
            memoryLimit: UInt,
            timeLimit: DispatchTimeInterval,
            logger: Logger,
            eventLoop: EventLoop
        ) -> Context {
            Context(
                requestID: requestID,
                memoryLimit: memoryLimit,
                timeLimit: timeLimit,
                logger: logger,
                eventLoop: eventLoop,
                allocator: ByteBufferAllocator()
            )
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
