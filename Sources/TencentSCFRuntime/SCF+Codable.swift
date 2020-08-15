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

import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import NIO
import NIOFoundationCompat
@_exported import TencentSCFRuntimeCore

/// Extension to the `SCF` companion to enable execution of cloud functions that take and return `Codable` events.
extension SCF {
    /// An asynchronous SCF Closure that takes a `In: Decodable` and returns a `Result<Out: Encodable, Error>` via a completion handler.
    public typealias CodableClosure<In: Decodable, Out: Encodable> = (SCF.Context, In, @escaping (Result<Out, Error>) -> Void) -> Void

    /// Run a cloud function defined by implementing the `CodableClosure` function.
    ///
    /// - Parameters:
    ///     - closure: `CodableClosure` based SCF function.
    ///
    /// - Note: This is a blocking operation that will run forever, as its lifecycle is managed by the Tencent SCF Runtime Engine.
    public static func run<In: Decodable, Out: Encodable>(_ closure: @escaping CodableClosure<In, Out>) {
        self.run(CodableClosureWrapper(closure))
    }

    /// An asynchronous SCF Closure that takes a `In: Decodable` and returns a `Result<Void, Error>` via a completion handler.
    public typealias CodableVoidClosure<In: Decodable> = (SCF.Context, In, @escaping (Result<Void, Error>) -> Void) -> Void

    /// Run a cloud function defined by implementing the `CodableVoidClosure` function.
    ///
    /// - Parameters:
    ///     - closure: `CodableVoidClosure` based SCF function.
    ///
    /// - Note: This is a blocking operation that will run forever, as its lifecycle is managed by the Tencent SCF Runtime Engine.
    public static func run<In: Decodable>(_ closure: @escaping CodableVoidClosure<In>) {
        self.run(CodableVoidClosureWrapper(closure))
    }
}

internal struct CodableClosureWrapper<In: Decodable, Out: Encodable>: SCFHandler {
    typealias In = In
    typealias Out = Out

    private let closure: SCF.CodableClosure<In, Out>

    init(_ closure: @escaping SCF.CodableClosure<In, Out>) {
        self.closure = closure
    }

    func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, event, callback)
    }
}

internal struct CodableVoidClosureWrapper<In: Decodable>: SCFHandler {
    typealias In = In
    typealias Out = Void

    private let closure: SCF.CodableVoidClosure<In>

    init(_ closure: @escaping SCF.CodableVoidClosure<In>) {
        self.closure = closure
    }

    func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, event, callback)
    }
}

/// Implementation of  a`ByteBuffer` to `In` decoding.
public extension EventLoopSCFHandler where In: Decodable {
    func decode(buffer: ByteBuffer) throws -> In {
        try self.decoder.decode(In.self, from: buffer)
    }
}

/// Implementation of  `Out` to `ByteBuffer` encoding.
public extension EventLoopSCFHandler where Out: Encodable {
    func encode(allocator: ByteBufferAllocator, value: Out) throws -> ByteBuffer? {
        try self.encoder.encode(value, using: allocator)
    }
}

/// Default `ByteBuffer` to `In` decoder using Foundation's JSONDecoder.
/// Advanced users that want to inject their own codec can do it by overriding these functions.
public extension EventLoopSCFHandler where In: Decodable {
    var decoder: SCFCodableDecoder {
        SCF.defaultJSONDecoder
    }
}

/// Default `Out` to `ByteBuffer` encoder using Foundation's JSONEncoder.
/// Advanced users that want to inject their own codec can do it by overriding these functions.
public extension EventLoopSCFHandler where Out: Encodable {
    var encoder: SCFCodableEncoder {
        SCF.defaultJSONEncoder
    }
}

public protocol SCFCodableDecoder {
    func decode<T: Decodable>(_ type: T.Type, from buffer: ByteBuffer) throws -> T
}

public protocol SCFCodableEncoder {
    func encode<T: Encodable>(_ value: T, using allocator: ByteBufferAllocator) throws -> ByteBuffer
}

private extension SCF {
    static let defaultJSONDecoder = JSONDecoder()
    static let defaultJSONEncoder = JSONEncoder()
}

extension JSONDecoder: SCFCodableDecoder {}

extension JSONEncoder: SCFCodableEncoder {
    public func encode<T>(_ value: T, using allocator: ByteBufferAllocator) throws -> ByteBuffer where T: Encodable {
        // NIO will resize the buffer if necessary.
        var buffer = allocator.buffer(capacity: 1024)
        try self.encode(value, into: &buffer)
        return buffer
    }
}
