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
// See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
// for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Logging
import NIO
import NIOHTTP1

/// An HTTP based client for SCF Runtime Engine. This encapsulates the RESTful methods exposed by the runtime engine:
/// - POST /runtime/init/ready
/// - GET /runtime/invocation/next
/// - POST /runtime/invocation/response
/// - POST /runtime/invocation/error
extension SCF {
    internal struct RuntimeClient {
        private let eventLoop: EventLoop
        private let allocator = ByteBufferAllocator()
        private let httpClient: HTTPClient

        init(eventLoop: EventLoop, configuration: Configuration.RuntimeEngine) {
            self.eventLoop = eventLoop
            self.httpClient = HTTPClient(eventLoop: eventLoop, configuration: configuration)
        }

        /// Requests invocation from the API server.
        func getNextInvocation(logger: Logger) -> EventLoopFuture<(Invocation, ByteBuffer)> {
            let url = Endpoint.getNextInvocation
            logger.debug("requesting work from scf runtime engine using \(url)")
            return self.httpClient.get(url: url, headers: RuntimeClient.defaultHeaders).flatMapThrowing { response in
                guard response.status == .ok else {
                    throw RuntimeError.badStatusCode(response.status)
                }
                let invocation = try Invocation(headers: response.headers)
                guard let event = response.body else {
                    throw RuntimeError.noBody
                }
                return (invocation, event)
            }.flatMapErrorThrowing { error in
                switch error {
                case HTTPClient.Errors.timeout:
                    throw RuntimeError.upstreamError("timeout")
                case HTTPClient.Errors.connectionResetByPeer:
                    throw RuntimeError.upstreamError("connectionResetByPeer")
                default:
                    throw error
                }
            }
        }

        /// Reports a result to the runtime engine.
        func reportResults(logger: Logger, invocation: Invocation, result: Result<ByteBuffer?, Error>) -> EventLoopFuture<Void> {
            let url: String
            var body: ByteBuffer?
            let headers: HTTPHeaders

            switch result {
            case .success(let buffer):
                url = Endpoint.postResponse
                body = buffer
                headers = RuntimeClient.defaultHeaders
            case .failure(let error):
                url = Endpoint.postError
                body = self.allocator.buffer(string: "\(error)")
                headers = RuntimeClient.errorHeaders
            }
            logger.debug("reporting results to scf runtime engine using \(url)")
            return self.httpClient.post(url: url, headers: headers, body: body).flatMapThrowing { response in
                guard response.status == .ok else {
                    throw RuntimeError.badStatusCode(response.status)
                }
                return ()
            }.flatMapErrorThrowing { error in
                switch error {
                case HTTPClient.Errors.timeout:
                    throw RuntimeError.upstreamError("timeout")
                case HTTPClient.Errors.connectionResetByPeer:
                    throw RuntimeError.upstreamError("connectionResetByPeer")
                default:
                    throw error
                }
            }
        }

        /// Reports initialization ready to the runtime engine.
        func reportInitializationReady(logger: Logger) -> EventLoopFuture<Void> {
            let url = Endpoint.postInitReady
            logger.info("reporting initialization ready to scf runtime engine using \(url)")
            return self.httpClient.post(url: url, headers: RuntimeClient.defaultHeaders, body: .init(string: " ")).flatMapThrowing { response in
                guard response.status == .ok else {
                    throw RuntimeError.badStatusCode(response.status)
                }
                return ()
            }.flatMapErrorThrowing { error in
                switch error {
                case HTTPClient.Errors.timeout:
                    throw RuntimeError.upstreamError("timeout")
                case HTTPClient.Errors.connectionResetByPeer:
                    throw RuntimeError.upstreamError("connectionResetByPeer")
                default:
                    throw error
                }
            }
        }

        /// Cancels the current request if one is already running. Only needed for debugging purposes.
        func cancel() {
            self.httpClient.cancel()
        }
    }
}

internal extension SCF {
    enum RuntimeError: Error {
        case badStatusCode(HTTPResponseStatus)
        case upstreamError(String)
        case invocationMissingHeader(String)
        case noBody
        case json(Error)
        case shutdownError(shutdownError: Error, runnerResult: Result<Int, Error>)
    }
}

extension SCF {
    internal struct Invocation {
        let requestID: String
        let memoryLimit: UInt
        let timeLimit: UInt

        init(headers: HTTPHeaders) throws {
            guard let requestID = headers.first(name: SCFHeaders.requestID), !requestID.isEmpty else {
                throw RuntimeError.invocationMissingHeader(SCFHeaders.requestID)
            }

            guard let memoryLimit = headers.first(name: SCFHeaders.memoryLimit),
                let memoryLimitInMB = UInt(memoryLimit)
            else {
                throw RuntimeError.invocationMissingHeader(SCFHeaders.memoryLimit)
            }

            guard let timeLimit = headers.first(name: SCFHeaders.timeLimit),
                let timeLimitInMs = UInt(timeLimit)
            else {
                throw RuntimeError.invocationMissingHeader(SCFHeaders.timeLimit)
            }

            self.requestID = requestID
            self.memoryLimit = memoryLimitInMB
            self.timeLimit = timeLimitInMs
        }
    }
}

extension SCF.RuntimeClient {
    internal static let defaultHeaders = HTTPHeaders([("user-agent", "Swift-SCF/Unknown")])

    /// These headers must be sent along an invocation or initialization error report.
    internal static let errorHeaders = HTTPHeaders([
        ("user-agent", "Swift-SCF/Unknown"),
    ])
}
