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
// Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Foundation
import NIO
import NIOHTTP1

internal struct MockServer {
    private let group: EventLoopGroup
    private let host: String
    private let port: Int

    public init() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.host = env("SCF_RUNTIME_API") ?? "127.0.0.1"
        self.port = env("SCF_RUNTIME_API_PORT").flatMap(Int.init) ?? 9001
    }

    func start() throws {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap { _ in
                    channel.pipeline.addHandler(HTTPHandler())
                }
            }
        try bootstrap.bind(host: self.host, port: self.port).flatMap { channel -> EventLoopFuture<Void> in
            guard let localAddress = channel.localAddress else {
                return channel.eventLoop.makeFailedFuture(ServerError.cantBind)
            }
            print("\(self) started and listening on \(localAddress)")
            return channel.eventLoop.makeSucceededFuture(())
        }.wait()
    }
}

internal final class HTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private var pending = CircularBuffer<(head: HTTPRequestHead, body: ByteBuffer?)>()

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = unwrapInboundIn(data)

        switch requestPart {
        case .head(let head):
            self.pending.append((head: head, body: nil))
        case .body(var buffer):
            var request = self.pending.removeFirst()
            if request.body == nil {
                request.body = buffer
            } else {
                request.body!.writeBuffer(&buffer)
            }
            self.pending.prepend(request)
        case .end:
            let request = self.pending.removeFirst()
            self.processRequest(context: context, request: request)
        }
    }

    func processRequest(context: ChannelHandlerContext, request: (head: HTTPRequestHead, body: ByteBuffer?)) {
        var responseStatus: HTTPResponseStatus
        var responseBody: String?
        var responseHeaders: [(String, String)]?

        if request.head.uri.hasSuffix("/next") {
            let requestId = UUID().uuidString.lowercased()
            responseStatus = .ok
            responseBody = "{ \"body\": \"\(requestId)\" }"
            responseHeaders = [
                (SCFHeaders.requestID, requestId),
                (SCFHeaders.memoryLimit, "128"),
                (SCFHeaders.timeLimit, "3000"),
            ]
        } else if request.head.uri.hasSuffix("/response") {
            responseStatus = .ok
        } else {
            responseStatus = .notFound
        }
        self.writeResponse(context: context, status: responseStatus, headers: responseHeaders, body: responseBody)
    }

    func writeResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, headers: [(String, String)]? = nil, body: String? = nil) {
        var headers = HTTPHeaders(headers ?? [])
        headers.add(name: "content-length", value: "\(body?.utf8.count ?? 0)")
        let head = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1), status: status, headers: headers)

        context.write(wrapOutboundOut(.head(head))).whenFailure { error in
            print("\(self) write error \(error)")
        }

        if let b = body {
            var buffer = context.channel.allocator.buffer(capacity: b.utf8.count)
            buffer.writeString(b)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer)))).whenFailure { error in
                print("\(self) write error \(error)")
            }
        }

        context.writeAndFlush(wrapOutboundOut(.end(nil))).whenComplete { result in
            if case .failure(let error) = result {
                print("\(self) write error \(error)")
            }
        }
    }
}

internal enum ServerError: Error {
    case notReady
    case cantBind
}

internal enum SCFHeaders {
    static let requestID = "request_id"
    static let memoryLimit = "memory_limit_in_mb"
    static let timeLimit = "time_limit_in_ms"
}

internal enum Mode: String {
    case string
    case json
}

func env(_ name: String) -> String? {
    guard let value = getenv(name) else {
        return nil
    }
    return String(cString: value)
}

// main
let server = MockServer()
try! server.start()
dispatchMain()
