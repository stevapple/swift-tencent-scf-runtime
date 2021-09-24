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

import NIOCore
import TencentSCFEvents
import TencentSCFRuntimeCore

// MARK: - Run SCF function

SCF.run { $0.eventLoop.makeSucceededFuture(APIGatewayProxyHandler()) }

// MARK: - Handler, Request and Response

struct APIGatewayProxyHandler: EventLoopSCFHandler {
    typealias In = APIGateway.Request<String>
    typealias Out = APIGateway.Response

    func handle(context: SCF.Context, event: APIGateway.Request<String>) -> EventLoopFuture<APIGateway.Response> {
        context.logger.debug("hello, api gateway!")
        return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .ok, body: .string("Hello, world!")))
    }
}
