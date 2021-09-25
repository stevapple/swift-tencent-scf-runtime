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
//
// This source file was part of the SwiftAWSLambdaRuntime open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import NIOCore
import TencentSCFRuntimeCore

struct EchoHandler: EventLoopSCFHandler {
    typealias Event = String
    typealias Output = String

    func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
        context.eventLoop.makeSucceededFuture(event)
    }
}

struct FailedHandler: EventLoopSCFHandler {
    typealias Event = String
    typealias Output = Void

    private let reason: String

    init(_ reason: String) {
        self.reason = reason
    }

    func handle(context: SCF.Context, event: String) -> EventLoopFuture<Void> {
        context.eventLoop.makeFailedFuture(TestError(self.reason))
    }
}
