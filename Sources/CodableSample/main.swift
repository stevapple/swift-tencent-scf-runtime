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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import NIO
import TencentSCFRuntime

struct Request: Codable {
    let body: String
}

struct Response: Codable {
    let body: String
}

// In this example we are receiving and responding with codables.  Request and Response
// above are examples of how to use codables to model your reqeuest and response objects.
struct Handler: EventLoopSCFHandler {
    typealias In = Request
    typealias Out = Response

    func handle(context: SCF.Context, event: Request) -> EventLoopFuture<Response> {
        // As an example, respond with the input event's reversed body.
        context.eventLoop.makeSucceededFuture(Response(body: String(event.body.reversed())))
    }
}

SCF.run(Handler())

// MARK: - this can also be expressed as a closure:

/*
 SCF.run { (_, request: Request, callback) in
     callback(.success(Response(body: String(request.body.reversed()))))
 }
 */
