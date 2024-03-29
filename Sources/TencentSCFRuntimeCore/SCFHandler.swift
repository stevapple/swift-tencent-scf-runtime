//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2020-2021 stevapple and the SwiftTencentSCFRuntime project authors
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
// Copyright (c) 2017-2021 Apple Inc. and the SwiftAWSLambdaRuntime project authors
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
import NIOCore

// MARK: - SCFHandler

#if compiler(>=5.5) && canImport(_Concurrency)
/// Strongly typed, processing protocol for a cloud function that takes a user defined `Event` and returns a user defined `Output` async.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol SCFHandler: EventLoopSCFHandler {
    /// The SCF initialization method
    /// Use this method to initialize resources that will be used in every request.
    ///
    /// Examples for this can be HTTP or database clients.
    /// - parameters:
    ///     - context: Runtime `InitializationContext`.
    init(context: SCF.InitializationContext) async throws

    /// The SCF handling method
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - parameters:
    ///     - event: Event of type `Event` representing the event or request.
    ///     - context: Runtime `Context`.
    ///
    /// - Returns: An SCF result ot type `Output`.
    func handle(_ event: Event, context: SCF.Context) async throws -> Output
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension SCFHandler {
    public func handle(_ event: Event, context: SCF.Context) -> EventLoopFuture<Output> {
        let promise = context.eventLoop.makePromise(of: Output.self)
        promise.completeWithTask {
            try await self.handle(event, context: context)
        }
        return promise.futureResult
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension SCFHandler {
    public static func main() {
        _ = SCF.run(handlerType: Self.self)
    }
}
#endif

// MARK: - EventLoopSCFHandler

/// Strongly typed, `EventLoopFuture` based processing protocol for an SCF function that takes a user defined `Event` and returns a user defined `Output` asynchronously.
/// `EventLoopSCFHandler` extends `ByteBufferSCFHandler`, performing `ByteBuffer` -> `Event` decoding and `Output` -> `ByteBuffer` encoding.
///
/// - Note: To implement a cloud function, implement either `SCFHandler` or the `EventLoopSCFHandler` protocol.
///         The `SCFHandler` will offload the SCF execution to a `DispatchQueue` making processing safer but slower
///         The `EventLoopSCFHandler` will execute the cloud function on the same `EventLoop` as the core runtime engine, making the processing faster but requires more care from the implementation to never block the `EventLoop`.
public protocol EventLoopSCFHandler: ByteBufferSCFHandler {
    associatedtype Event
    associatedtype Output

    /// The SCF handling method.
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - Parameters:
    ///     - event: Event of type `Event` representing the event or request.
    ///     - context: Runtime `Context`.
    ///
    /// - Returns: An `EventLoopFuture` to report the result of the SCF function back to the runtime engine.
    ///            The `EventLoopFuture` should be completed with either a response of type `Output` or an `Error`.
    func handle(_ event: Event, context: SCF.Context) -> EventLoopFuture<Output>

    /// Encode a response of type `Output` to `ByteBuffer`.
    /// Concrete SCF handlers implement this method to provide coding functionality.
    ///
    /// - Parameters:
    ///     - allocator: A `ByteBufferAllocator` to help allocate the `ByteBuffer`.
    ///     - value: Response of type `Output`.
    ///
    /// - Returns: A `ByteBuffer` with the encoded version of the `value`.
    func encode(allocator: ByteBufferAllocator, value: Output) throws -> ByteBuffer?

    /// Decode a`ByteBuffer` to a request or event of type `Event`
    /// Concrete SCF handlers implement this method to provide coding functionality.
    ///
    /// - Parameters:
    ///     - buffer: The `ByteBuffer` to decode.
    ///
    /// - Returns: A request or event of type `Event`.
    func decode(buffer: ByteBuffer) throws -> Event
}

extension EventLoopSCFHandler {
    /// Driver for `ByteBuffer` -> `Event` decoding and `Output` -> `ByteBuffer` encoding
    @inlinable
    public func handle(_ event: ByteBuffer, context: SCF.Context) -> EventLoopFuture<ByteBuffer?> {
        let input: Event
        do { input = try self.decode(buffer: event) }
        catch {
            return context.eventLoop.makeFailedFuture(CodecError.requestDecoding(error))
        }

        return self.handle(input, context: context).flatMapThrowing { output in
            do {
                return try self.encode(allocator: context.allocator, value: output)
            } catch {
                throw CodecError.responseEncoding(error)
            }
        }
    }

    private func decodeIn(buffer: ByteBuffer) -> Result<Event, Error> {
        do {
            return .success(try self.decode(buffer: buffer))
        } catch {
            return .failure(error)
        }
    }

    private func encodeOut(allocator: ByteBufferAllocator, value: Output) -> Result<ByteBuffer?, Error> {
        do {
            return .success(try self.encode(allocator: allocator, value: value))
        } catch {
            return .failure(error)
        }
    }
}

/// Implementation of  `ByteBuffer` to `Void` decoding.
extension EventLoopSCFHandler where Output == Void {
    @inlinable
    public func encode(allocator: ByteBufferAllocator, value: Void) throws -> ByteBuffer? {
        nil
    }
}

// MARK: - ByteBufferSCFHandler

/// An `EventLoopFuture` based processing protocol for an SCF function that takes a `ByteBuffer` and returns a `ByteBuffer?` asynchronously.
///
/// - Note: This is a low level protocol designed to power the higher level `EventLoopSCFHandler` and `SCFHandler` based APIs.
///         Most users are not expected to use this protocol.
public protocol ByteBufferSCFHandler {
    /// The SCF handling method.
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - Parameters:
    ///     - event: The event or input payload encoded as `ByteBuffer`.
    ///     - context: Runtime `Context`.
    ///
    /// - Returns: An `EventLoopFuture` to report the result of the SCF function back to the runtime engine.
    ///            The `EventLoopFuture` should be completed with either a response encoded as `ByteBuffer` or an `Error`.
    func handle(_ event: ByteBuffer, context: SCF.Context) -> EventLoopFuture<ByteBuffer?>

    /// Clean up the SCF resources asynchronously.
    /// Concrete SCF handlers implement this method to shutdown resources like `HTTPClient`s and database connections.
    ///
    /// - Note: In case your SCF function fails while creating your `SCFHandler` in the `HandlerFactory`, this method
    ///         **is not invoked**. In this case you must cleanup the created resources immediately in the `HandlerFactory`.
    func shutdown(context: SCF.ShutdownContext) -> EventLoopFuture<Void>
}

extension ByteBufferSCFHandler {
    public func shutdown(context: SCF.ShutdownContext) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededFuture(())
    }
}

@usableFromInline
enum CodecError: Error {
    case requestDecoding(Error)
    case responseEncoding(Error)
}
