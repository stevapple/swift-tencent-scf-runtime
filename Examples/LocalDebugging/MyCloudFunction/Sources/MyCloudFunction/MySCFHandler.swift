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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Shared
import TencentSCFRuntime

// Set LOCAL_SCF_SERVER_ENABLED env variable to "true" to start a local server simulator
// which will allow local debugging.
@main
struct MySCFHandler: SCFHandler {
    typealias Event = Request
    typealias Output = Response

    init(context: SCF.InitializationContext) async throws {
        // setup your resources that you want to reuse for every invocation here.
    }

    func handle(_ event: Request, context: SCF.Context) async throws -> Response {
        // TODO: something useful
        Response(message: "Hello, \(event.name)!")
    }
}
