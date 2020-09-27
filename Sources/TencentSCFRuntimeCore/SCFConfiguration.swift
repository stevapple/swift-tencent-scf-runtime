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

extension SCF {
    internal struct Configuration: CustomStringConvertible {
        let general: General
        let lifecycle: Lifecycle
        let runtimeEngine: RuntimeEngine

        init() {
            self.init(general: .init(), lifecycle: .init(), runtimeEngine: .init())
        }

        init(general: General? = nil, lifecycle: Lifecycle? = nil, runtimeEngine: RuntimeEngine? = nil) {
            self.general = general ?? General()
            self.lifecycle = lifecycle ?? Lifecycle()
            self.runtimeEngine = runtimeEngine ?? RuntimeEngine()
        }

        struct General: CustomStringConvertible {
            let logLevel: Logger.Level

            init(logLevel: Logger.Level? = nil) {
                self.logLevel = logLevel ?? Env["LOG_LEVEL"].flatMap(Logger.Level.init) ?? .info
            }

            var description: String {
                "\(General.self)(logLevel: \(self.logLevel))"
            }
        }

        struct Lifecycle: CustomStringConvertible {
            let id: String
            let maxTimes: Int
            let stopSignal: Signal

            init(id: String? = nil, maxTimes: Int? = nil, stopSignal: Signal? = nil) {
                self.id = id ?? "\(DispatchTime.now().uptimeNanoseconds)"
                self.maxTimes = maxTimes ?? Env["MAX_REQUESTS"].flatMap(Int.init) ?? 0
                self.stopSignal = stopSignal ?? Env["STOP_SIGNAL"].flatMap(Int32.init).flatMap(Signal.init) ?? Signal.TERM
                precondition(self.maxTimes >= 0, "maxTimes must be equal or larger than 0")
            }

            var description: String {
                "\(Lifecycle.self)(id: \(self.id), maxTimes: \(self.maxTimes), stopSignal: \(self.stopSignal))"
            }
        }

        struct RuntimeEngine: CustomStringConvertible {
            let ip: String
            let port: Int
            let keepAlive: Bool
            let requestTimeout: TimeAmount?

            init(address: String? = nil, keepAlive: Bool? = nil, requestTimeout: TimeAmount? = nil) {
                if let ipPort = address?.split(separator: ":") {
                    guard ipPort.count == 2, let port = Int(ipPort[1]) else {
                        preconditionFailure("invalid ip+port configuration \(ipPort)")
                    }
                    self.ip = String(ipPort[0])
                    self.port = port
                } else {
                    self.ip = Env["SCF_RUNTIME_API"] ?? "127.0.0.1"
                    self.port = Env["SCF_RUNTIME_API_PORT"].flatMap(Int.init) ?? 9001
                }
                self.keepAlive = keepAlive ?? Env["KEEP_ALIVE"].flatMap(Bool.init) ?? true
                self.requestTimeout = requestTimeout ?? Env["REQUEST_TIMEOUT"].flatMap(Int64.init).flatMap { .milliseconds($0) }
            }

            var description: String {
                "\(RuntimeEngine.self)(ip: \(self.ip), port: \(self.port), keepAlive: \(self.keepAlive), requestTimeout: \(String(describing: self.requestTimeout))"
            }
        }

        var description: String {
            "\(Configuration.self)\n  \(self.general))\n  \(self.lifecycle)\n  \(self.runtimeEngine)"
        }
    }
}
