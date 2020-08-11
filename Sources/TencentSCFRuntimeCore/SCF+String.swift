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

import NIO

/// Extension to the `SCF` companion to enable execution of cloud functions that take and return `String` events.
extension SCF {
    /// An asynchronous SCF Closure that takes a `String` and returns a `Result<String, Error>` via a completion handler.
    public typealias StringClosure = (SCF.Context, String, @escaping (Result<String, Error>) -> Void) -> Void

    /// Run a cloud function defined by implementing the `StringClosure` function.
    ///
    /// - parameters:
    ///     - closure: `StringClosure` based SCF function.
    ///
    /// - note: This is a blocking operation that will run forever, as its lifecycle is managed by the Tencent SCF Runtime Engine.
    public static func run(_ closure: @escaping StringClosure) {
        self.run(closure: closure)
    }

    /// An asynchronous SCF Closure that takes a `String` and returns a `Result<Void, Error>` via a completion handler.
    public typealias StringVoidClosure = (SCF.Context, String, @escaping (Result<Void, Error>) -> Void) -> Void

    /// Run a cloud function defined by implementing the `StringVoidClosure` function.
    ///
    /// - parameters:
    ///     - closure: `StringVoidClosure` based SCF function.
    ///
    /// - note: This is a blocking operation that will run forever, as its lifecycle is managed by the Tencent SCF Runtime Engine.
    public static func run(_ closure: @escaping StringVoidClosure) {
        self.run(closure: closure)
    }

    // for testing only
    @discardableResult
    internal static func run(configuration: Configuration = .init(), closure: @escaping StringClosure) -> Result<Int, Error> {
        self.run(configuration: configuration, handler: StringClosureWrapper(closure))
    }

    // for testing only
    @discardableResult
    internal static func run(configuration: Configuration = .init(), closure: @escaping StringVoidClosure) -> Result<Int, Error> {
        self.run(configuration: configuration, handler: StringVoidClosureWrapper(closure))
    }
}

internal struct StringClosureWrapper: SCFHandler {
    typealias In = String
    typealias Out = String

    private let closure: SCF.StringClosure

    init(_ closure: @escaping SCF.StringClosure) {
        self.closure = closure
    }

    func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, event, callback)
    }
}

internal struct StringVoidClosureWrapper: SCFHandler {
    typealias In = String
    typealias Out = Void

    private let closure: SCF.StringVoidClosure

    init(_ closure: @escaping SCF.StringVoidClosure) {
        self.closure = closure
    }

    func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, event, callback)
    }
}

public extension EventLoopSCFHandler where In == String {
    /// Implementation of a `ByteBuffer` to `String` decoding.
    func decode(buffer: ByteBuffer) throws -> String {
        var buffer = buffer
        guard let string = buffer.readString(length: buffer.readableBytes) else {
            fatalError("buffer.readString(length: buffer.readableBytes) failed")
        }
        return string
    }
}

public extension EventLoopSCFHandler where Out == String {
    /// Implementation of `String` to `ByteBuffer` encoding.
    func encode(allocator: ByteBufferAllocator, value: String) throws -> ByteBuffer? {
        // FIXME: reusable buffer
        var buffer = allocator.buffer(capacity: value.utf8.count)
        buffer.writeString(value)
        return buffer
    }
}
