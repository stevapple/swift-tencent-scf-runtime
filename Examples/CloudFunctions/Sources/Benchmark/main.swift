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
// Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import NIO
import TencentSCFRuntimeCore

// If you would like to benchmark Swift's SCF Runtime, use this example which is more performant.
// `EventLoopSCFHandler` does not offload the cloud function processing to a separate thread
// while the Closure-based handlers do.
SCF.run(BenchmarkHandler())

struct BenchmarkHandler: EventLoopSCFHandler {
    typealias In = String
    typealias Out = String

    func handle(context: SCF.Context, event: String) -> EventLoopFuture<String> {
        context.eventLoop.makeSucceededFuture("Hello, world!")
    }
}
