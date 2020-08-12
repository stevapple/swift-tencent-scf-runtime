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
import TencentSCFEvents
import TencentSCFRuntime

// MARK: - Run SCF function

SCF.run(APIGatewayProxySCF())

// MARK: - Handler, Request and Response

// FIXME: Use proper Event abstractions once added to TencentSCFRuntime
struct APIGatewayProxySCF: EventLoopSCFHandler {
    public typealias In = APIGateway.Request<String>
    public typealias Out = APIGateway.Response

    public func handle(context: SCF.Context, event: APIGateway.Request<String>) -> EventLoopFuture<APIGateway.Response> {
        context.logger.debug("hello, api gateway!")
        return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .ok, body: "Hello, world!"))
    }
}
