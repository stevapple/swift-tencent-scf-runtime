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

/// An HTTP based client for AWS Runtime Engine. This encapsulates the RESTful methods exposed by the Runtime Engine:
/// * /runtime/invocation/next
/// * /runtime/invocation/response
/// * /runtime/invocation/error
/// * /runtime/init/error
extension Lambda {
    internal struct RuntimeClient {
        private let eventLoop: EventLoop
        private let allocator = ByteBufferAllocator()
        private let httpClient: HTTPClient

        init(eventLoop: EventLoop, configuration: Configuration.RuntimeEngine) {
            self.eventLoop = eventLoop
            self.httpClient = HTTPClient(eventLoop: eventLoop, configuration: configuration)
        }

        /// Requests invocation from the control plane.
        func getNextInvocation(logger: Logger) -> EventLoopFuture<(Invocation, ByteBuffer)> {
            let url = Consts.getNextInvocationURL
            logger.debug("requesting work from lambda runtime engine using \(url)")
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

        /// Reports a result to the Runtime Engine.
        func reportResults(logger: Logger, invocation: Invocation, result: Result<ByteBuffer?, Error>) -> EventLoopFuture<Void> {
            let url: String
            var body: ByteBuffer?
            let headers: HTTPHeaders

            switch result {
            case .success(let buffer):
                url = Consts.postResponseURL
                body = buffer
                headers = RuntimeClient.defaultHeaders
            case .failure(let error):
                url = Consts.postErrorURL
                let errorResponse = ErrorResponse(errorType: Consts.functionError, errorMessage: "\(error)")
                let bytes = errorResponse.toJSONBytes()
                body = self.allocator.buffer(capacity: bytes.count)
                body!.writeBytes(bytes)
                headers = RuntimeClient.errorHeaders
            }
            logger.debug("reporting results to lambda runtime engine using \(url)")
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

        /// Reports an initialization error to the Runtime Engine.
        func reportInitializationError(logger: Logger, error: Error) -> EventLoopFuture<Void> {
            let url = Consts.postInitErrorURL
            let errorResponse = ErrorResponse(errorType: Consts.initializationError, errorMessage: "\(error)")
            let bytes = errorResponse.toJSONBytes()
            var body = self.allocator.buffer(capacity: bytes.count)
            body.writeBytes(bytes)
            logger.warning("reporting initialization error to lambda runtime engine using \(url)")
            return self.httpClient.post(url: url, headers: RuntimeClient.errorHeaders, body: body).flatMapThrowing { response in
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

        /// Reports initialization ready to the Runtime Engine.
        func reportInitializationReady(logger: Logger) -> EventLoopFuture<Void> {
            let url = Consts.postInitReadyURL
            logger.info("reporting initialization ready to lambda runtime engine using \(url)")
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

        /// Cancels the current request, if one is running. Only needed for debugging purposes
        func cancel() {
            self.httpClient.cancel()
        }
    }
}

internal extension Lambda {
    enum RuntimeError: Error {
        case badStatusCode(HTTPResponseStatus)
        case upstreamError(String)
        case invocationMissingHeader(String)
        case noBody
        case json(Error)
        case shutdownError(shutdownError: Error, runnerResult: Result<Int, Error>)
    }
}

internal struct ErrorResponse: Codable {
    var errorType: String
    var errorMessage: String
}

internal extension ErrorResponse {
    func toJSONBytes() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(UInt8(ascii: "{"))
        bytes.append(contentsOf: #""errorType":"# .utf8)
        self.errorType.encodeAsJSONString(into: &bytes)
        bytes.append(contentsOf: #","errorMessage":"# .utf8)
        self.errorMessage.encodeAsJSONString(into: &bytes)
        bytes.append(UInt8(ascii: "}"))
        return bytes
    }
}

extension Lambda {
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

extension Lambda.RuntimeClient {
    internal static let defaultHeaders = HTTPHeaders([("user-agent", "Swift-Lambda/Unknown")])

    /// These headers must be sent along an invocation or initialization error report
    internal static let errorHeaders = HTTPHeaders([
        ("user-agent", "Swift-Lambda/Unknown"),
        ("lambda-runtime-function-error-type", "Unhandled"),
    ])
}
