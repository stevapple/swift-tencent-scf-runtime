# Swift Tencent SCF Runtime

Many modern systems have client components like iOS, macOS or watchOS applications as well as server components that those clients interact with. Serverless functions are often the easiest and most efficient way for client application developers to extend their applications into the cloud.

Serverless functions are increasingly becoming a popular choice for running event-driven or otherwise ad-hoc compute tasks in the cloud. They power mission critical microservices and data intensive workloads. In many cases, serverless functions allow developers to more easily scale and control compute costs given their on-demand nature.

When using serverless functions, attention must be given to resource utilization as it directly impacts the costs of the system. This is where Swift shines! With its low memory footprint, deterministic performance, and quick start time, Swift is a fantastic match for the serverless functions architecture.

Combine this with Swift's developer friendliness, expressiveness, and emphasis on safety, and we have a solution that is great for developers at all skill levels, scalable, and cost effective.

Swift Tencent SCF Runtime is a forked version form [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime), designed to make building cloud functions in Swift simple and safe. The library is an implementation of the [Tencent SCF Custom Runtime API](https://cloud.tencent.com/document/product/583/47274#custom-runtime-.E8.BF.90.E8.A1.8C.E6.97.B6-api) and uses an embedded asynchronous HTTP Client based on [SwiftNIO](http://github.com/apple/swift-nio) that is fine-tuned for performance in the SCF Custom Runtime context. The library provides a multi-tier API that allows building a range of cloud functions: From quick and simple Closures to complex, performance-sensitive event handlers.

## Project status

This is the beginning of an open-source project actively seeking contributions.
While the core API is considered stable, the API may still evolve as we get closer to a `1.0` version.
There are several areas which need additional attention, including but not limited to:

* Further performance tuning
* Additional trigger events
* Additional documentation and best practices
* Additional examples

By August 2020, [SCF Custom Runtime](https://cloud.tencent.com/document/product/583/47274) is also at an early stage. You may encounter some problems triggered by the SCF Runtime Engine itself, or the API changes and deprecations. You are welcome to open issues actively on those problems.

## Getting started

If you have used [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime), you may find most of the APIs familiar. If you have never used Tencent SCF, AWS Lambda or Docker before, check out this [getting started guide](https://fabianfett.de/getting-started-with-swift-aws-lambda-runtime) which helps you with every step from zero to a running cloud function.

First, create a SwiftPM project and pull Swift Tencent SCF Runtime as dependency into your project:

```swift
// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "my-cloud-function",
    products: [
        .executable(name: "MyCloudFunction", targets: ["MyCloudFunction"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stevapple/swift-tencent-scf-runtime.git", from: "0.0.3"),
    ],
    targets: [
        .target(name: "MyCloudFunction", dependencies: [
            .product(name: "TencentSCFRuntime", package: "tencent-scf-runtime"),
        ]),
    ]
)
```

Next, create a `main.swift` and implement your cloud function.

### Using Closures

The simplest way to use `TencentSCFRuntime` is to pass in a closure, for example:

```swift
// Import the module.
import TencentSCFRuntime

// In this example we are receiving and responding with strings.
SCF.run { (context, name: String, callback: @escaping (Result<String, Error>) -> Void) in
    callback(.success("Hello, \(name)"))
}
 ```

More commonly, the event would be a JSON, which is modeled using `Codable`, for example:

```swift
// Import the module.
import TencentSCFRuntime

// Request, uses Decodable for transparent JSON decoding.
private struct Request: Decodable {
    let name: String
}

// Response, uses Encodable for transparent JSON encoding.
private struct Response: Encodable {
    let message: String
}

// In this example we are receiving and responding with `Codable`.
SCF.run { (context, request: Request, callback: @escaping (Result<Response, Error>) -> Void) in
    callback(.success(Response(message: "Hello, \(request.name)")))
}
```

Since most SCF functions are triggered by events originating in the Tencent Cloud platform like `CMQ`, `COS` or `APIGateway`, the package also includes a `TencentSCFEvents` module that provides implementations for most common SCF event types to further simplify writing SCF functions. For example, handling a `CMQ` event:

```swift
// Import the modules.
import TencentSCFRuntime
import TencentSCFEvents

// In this example we are receiving CMQ Messages from a CMQ Topic, with no response (Void).
SCF.run { (context, event: CMQ.Topic.Event, callback: @escaping (Result<Void, Error>) -> Void) in
    for record in event.records {
        ...
    }
    callback(.success(Void()))
}
```

Modeling SCF functions as Closures is both simple and safe. Swift Tencent SCF Runtime will ensure that the user-provided code is offloaded from the network processing thread such that even if the code becomes slow to respond or gets hang, the underlying process can continue to function. This safety comes at a small performance penalty from context switching between threads. In many cases, the simplicity and safety of using the Closure based API is often preferred over the complexity of the performance-oriented API.

### Using EventLoopSCFHandler

Performance sensitive cloud functions may choose to use a more complex API which allows user code to run on the same thread as the networking handlers. Swift Tencent SCF Runtime uses [SwiftNIO](https://github.com/apple/swift-nio) as its underlying networking engine which means the APIs are based on [SwiftNIO](https://github.com/apple/swift-nio) concurrency primitives like the `EventLoop` and `EventLoopFuture`. For example:

```swift
// Import the modules.
import TencentSCFRuntime
import TencentSCFEvents
import NIO

// Our SCF handler, conforms to EventLoopSCFHandler.
struct Handler: EventLoopSCFHandler {
    typealias In = COS.Event // Request type
    typealias Out = Void // Response type

    // In this example we are receiving a COS Event, with no response (Void).
    func handle(context: SCF.Context, event: In) -> EventLoopFuture<Out> {
        ...
        context.eventLoop.makeSucceededFuture(Void())
    }
}

SCF.run(Handler())
```

Beyond the small cognitive complexity of using the `EventLoopFuture` based APIs, note these APIs should be used with extra care. An `EventLoopSCFHandler` will execute the user code on the same `EventLoop` (thread) as the library, making processing faster but requiring the user code to never call blocking APIs as it might prevent the underlying process from functioning.

## Deploying to SCF Platform

To deploy SCF functions to Tencent SCF Platform, you need to compile the code for CentOS 7.6 which is the OS used on SCF microVMs, package it as a Zip file, and upload to Tencent Cloud.

Tencent Cloud offers several tools to interact and deploy cloud functions to SCF including [TCCLI](https://cloud.tencent.com/product/cli) and [Serverless Framework](https://serverless.com/cn/). The [Examples Directory](/Examples) includes complete sample build and deployment scripts that utilize these tools.

Note the examples mentioned above use dynamic linking, therefore bundle the required Swift libraries in the Zip package along side the executable. You may choose to link the SCF function statically (using `-static-stdlib`) which could improve performance but requires additional linker flags.

To build the SCF function for CentOS 7.6, use the Docker image published on [Swift toolchains for SCF](https://hub.docker.com/r/stevapple/swift-scf), as demonstrated in the examples.

## Architecture

The library defines three protocols for the implementation of an SCF Handler. From low-level to more convenient:

### ByteBufferSCFHandler

An `EventLoopFuture` based processing protocol for an SCF function that takes a `ByteBuffer` and returns a `ByteBuffer?` asynchronously.  

`ByteBufferSCFHandler` is the lowest level protocol designed to power the higher level `EventLoopSCFHandler` and `SCFHandler` based APIs. Users are not expected to use this protocol, though some performance sensitive applications that operate at the `ByteBuffer` level or have special serialization needs may choose to do so.

```swift
public protocol ByteBufferSCFHandler {
    /// The SCF handling method.
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - parameters:
    ///     - context: Runtime `Context`.
    ///     - event: The event or input payload encoded as `ByteBuffer`.
    ///
    /// - Returns: An `EventLoopFuture` to report the result of the SCF function back to the runtime engine.
    ///            The `EventLoopFuture` should be completed with either a response encoded as `ByteBuffer` or an `Error`.
    func handle(context: SCF.Context, event: ByteBuffer) -> EventLoopFuture<ByteBuffer?>

    /// Clean up the SCF resources asynchronously.
    /// Concrete SCF handlers implement this method to shutdown resources like `HTTPClient`s and database connections.
    ///
    /// - Note: In case your SCF function fails while creating your `SCFHandler` in the `HandlerFactory`, this method
    ///         **is not invoked**. In this case you must cleanup the created resources immediately in the `HandlerFactory`.
    func shutdown(context: SCF.ShutdownContext) -> EventLoopFuture<Void>
}
```

### EventLoopSCFHandler

`EventLoopSCFHandler` is a strongly typed, `EventLoopFuture` based asynchronous processing protocol for an SCF function that takes a user defined In and returns a user defined Out.

`EventLoopSCFHandler` extends `ByteBufferSCFHandler`, providing `ByteBuffer` -> `In` decoding and `Out` -> `ByteBuffer?` encoding for `Codable` and String.

`EventLoopSCFHandler` executes the user provided cloud function on the same `EventLoop` as the core runtime engine, making the processing fast but requires more care from the implementation to never block the `EventLoop`. It it designed for performance sensitive applications that use `Codable` or String based cloud functions.

```swift
public protocol EventLoopSCFHandler: ByteBufferSCFHandler {
    associatedtype In
    associatedtype Out

    /// The SCF handling method.
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - parameters:
    ///     - context: Runtime `Context`.
    ///     - event: Event of type `In` representing the event or request.
    ///
    /// - Returns: An `EventLoopFuture` to report the result of the SCF function back to the runtime engine.
    ///            The `EventLoopFuture` should be completed with either a response of type `Out` or an `Error`.
    func handle(context: SCF.Context, event: In) -> EventLoopFuture<Out>

    /// Encode a response of type `Out` to `ByteBuffer`.
    /// Concrete SCF handlers implement this method to provide coding functionality.
    /// - parameters:
    ///     - allocator: A `ByteBufferAllocator` to help allocate the `ByteBuffer`.
    ///     - value: Response of type `Out`.
    ///
    /// - Returns: A `ByteBuffer` with the encoded version of the `value`.
    func encode(allocator: ByteBufferAllocator, value: Out) throws -> ByteBuffer?

    /// Decode a`ByteBuffer` to a request or event of type `In`
    /// Concrete SCF handlers implement this method to provide coding functionality.
    ///
    /// - parameters:
    ///     - buffer: The `ByteBuffer` to decode.
    ///
    /// - Returns: A request or event of type `In`.
    func decode(buffer: ByteBuffer) throws -> In
}
```

### SCFHandler

`SCFHandler` is a strongly typed, completion handler based asynchronous processing protocol for an SCF function that takes a user defined In and returns a user defined Out.

`SCFHandler` extends `ByteBufferSCFHandler`, performing `ByteBuffer` -> `In` decoding and `Out` -> `ByteBuffer` encoding for `Codable` and String.

`SCFHandler` offloads the user provided SCF execution to a `DispatchQueue` making processing safer but slower.

```swift
public protocol SCFHandler: EventLoopSCFHandler {
    /// Defines to which `DispatchQueue` the SCF execution is offloaded to.
    var offloadQueue: DispatchQueue { get }

    /// The SCF handling method.
    /// Concrete SCF handlers implement this method to provide the SCF functionality.
    ///
    /// - parameters:
    ///     - context: Runtime `Context`.
    ///     - event: Event of type `In` representing the event or request.
    ///     - callback: Completion handler to report the result of the SCF function back to the runtime engine.
    ///                 The completion handler expects a `Result` with either a response of type `Out` or an `Error`.
    func handle(context: SCF.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void)
}
```

### Closures

In addition to protocol-based SCF functions, the library provides support for Closure-based ones, as demonstrated in the overview section above. Closure-based SCF functions are based on the `SCFHandler` protocol which mean they are safer. For most use cases, Closure-based cloud function is a great fit and users are encouraged to use them.

The library includes implementations for `Codable` and String based SCF functions. Since Tencent Cloud messages are primarily JSON based, this can cover the most common use cases.

```swift
public typealias CodableClosure<In: Decodable, Out: Encodable> = (SCF.Context, In, @escaping (Result<Out, Error>) -> Void) -> Void
```

```swift
public typealias StringClosure = (SCF.Context, String, @escaping (Result<String, Error>) -> Void) -> Void
```

This design allows for additional event types as well, and such SCF implementation can extend one of the above protocols and provided their own `ByteBuffer` -> `In` decoding and `Out` -> `ByteBuffer` encoding.

### Context

When calling the user provided SCF function, the library provides a `Context` class that provides metadata about the execution context, as well as utilities for logging and allocating buffers.

```swift
public final class Context: CustomDebugStringConvertible {
    /// The request ID, which identifies the request that triggered the function invocation.
    public let requestID: String

    /// The memory limit of the cloud function in MB.
    public let memoryLimit: UInt

    /// The time limit of the cloud function event in ms.
    public let timeLimit: DispatchTimeInterval

    /// The timestamp that the function times out.
    public let deadline: DispatchWallTime

    /// The UIN of cloud function actor.
    public static let uin: String

    /// The APPID that the cloud function belongs to.
    public static let appid: String

    /// The Tencent Cloud region that the cloud function is in.
    public static let region: String

    /// The name of the cloud function.
    public static let name: String

    /// The namespace of the cloud function.
    public static let namespace: String

    /// The version of the cloud function.
    public static let version: Version

    /// `Logger` to log with.
    ///
    /// - note: The `LogLevel` can be configured using the `LOG_LEVEL` environment variable.
    public let logger: Logger

    /// The `EventLoop` the SCF function is executed on. Use this to schedule work with.
    /// This is useful when implementing the `EventLoopSCFHandler` protocol.
    ///
    /// - note: The `EventLoop` is shared with the SCF Runtime Engine and should be handled with extra care.
    ///         Most importantly the `EventLoop` must never be blocked.
    public let eventLoop: EventLoop

    /// `ByteBufferAllocator` to allocate `ByteBuffer`.
    /// This is useful when implementing `EventLoopSCFHandler`.
    public let allocator: ByteBufferAllocator
}
```

### Configuration

The library’s behavior can be fine tuned using environment variables based configuration. The library supported the following environment variables:

* `LOG_LEVEL`: Define the logging level as defined by [SwiftLog](https://github.com/apple/swift-log). Set to INFO by default.
* `MAX_REQUESTS`: Max cycles the library can handle before exiting. Set to none by default.
* `STOP_SIGNAL`: Signal to capture for termination. Set to TERM by default.
* `REQUEST_TIMEOUT`:  Max time to wait for responses to come back from the SCF runtime engine. Set to none by default.

### SCF Runtime Engine Integration

The library is designed to integrate with SCF Runtime Engine via the [SCF Custom Runtime API](https://cloud.tencent.com/document/product/583/47274#custom-runtime-.E8.BF.90.E8.A1.8C.E6.97.B6-api) which was introduced as part of [SCF Custom Runtime](https://cloud.tencent.com/document/product/583/47274) in 2020. The latter is an HTTP server that exposes three main RESTful endpoint:

* `/runtime/invocation/next`
* `/runtime/invocation/response`
* `/runtime/invocation/error`

A single SCF execution workflow is made of the following steps:

1. The library calls SCF Runtime Engine `/next` endpoint to retrieve the next invocation request.
2. The library parses the response HTTP headers and populate the Context object.
3. The library reads the `/next` response body and attempt to decode it. Typically it decodes to user provided `In` type which extends `Decodable`, but users may choose to write SCF functions that receive the input as String or `ByteBuffer` which require less, or no decoding.
4. The library hands off the `Context` and `In` event to the user provided handler. In the case of `SCFHandler` based handler this is done on a dedicated `DispatchQueue`, providing isolation between user's and the library's code.
5. User provided handler processes the request asynchronously, invoking a callback or returning a future upon completion, which returns a Result type with the Out or Error populated.
6.  In case of error, the library posts to SCF Runtime Engine `/error` endpoint to provide the error details, which will show up on SCF logs.
7. In case of success, the library will attempt to encode the response. Typically it encodes from user provided `Out` type which extends `Encodable`, but users may choose to write SCF functions that return a String or `ByteBuffer`, which require less, or no encoding. The library then posts the response to SCF Runtime Engine `/response` endpoint to provide the response to the callee.

The library encapsulates the workflow via the internal `SCFRuntimeClient` and `SCFRunner` structs respectively.

### Lifecycle Management

SCF Runtime Engine controls the Application lifecycle and in the happy case never terminates the application, only suspends it's execution when no work is avaialble.

As such, the library main entry point is designed to run forever in a blocking fashion, performing the workflow described above in an endless loop.

That loop is broken if/when an internal error occurs, such as a failure to communicate with SCF Custom Runtime Engine API, or under other unexpected conditions.

By default, the library also registers a Signal handler that traps `INT` and `TERM` , which are typical Signals used in modern deployment platforms to communicate shutdown request.

### Integration with Tencent Cloud Platform Events

Serverless Cloud Functions can be invoked directly from the SCF console, SCF API, TCCLI and Tencent Cloud toolkit. More commonly, they are invoked as a reaction to an events coming from the Tencent Cloud platform. To make it easier to integrate with Tencent Cloud platform events, the library includes an `TencentSCFEvents` target which provides abstractions for many commonly used events. Additional events can be easily modeled when needed following the same patterns set by `TencentSCFEvents`. Integration points with the Tencent Cloud platform include:

* [APIGateway Requests](https://cloud.tencent.com/document/product/583/12513)
* [COS Events](https://cloud.tencent.com/document/product/583/9707)
* [Timer Events](https://cloud.tencent.com/document/product/583/9708)
* [CMQ Topic Messages](https://cloud.tencent.com/document/product/583/11517)
* [CKafka Messages](https://cloud.tencent.com/document/product/583/17530)

**Note**: Each one of the integration points mentioned above includes a set of `Decodable` structs that transform Tencent Cloud's data model for these APIs. APIGateway response is wrapped into an `Encodable` struct with three different initializers to help you build any valid response.

## Performance

Cloud functions performance is usually measured across two axes:

- **Cold start times**: The time it takes for a cloud function to startup, ask for an invocation and process the first invocation.

- **Warm invocation times**: The time it takes for a cloud function to process an invocation after the cloud function has been invoked at least once.

Larger packages size (Zip file uploaded to SCF platform) negatively impact the cold start time, since SCF needs to download and unpack the package before starting the process.

Swift provides great Unicode support via [ICU](http://site.icu-project.org/home). Therefore, Swift-based SCF functions include the ICU libraries which tend to be large. This impacts the download time mentioned above and an area for further optimization. Some of the alternatives worth exploring are using the system ICU that comes with CentOS 7 (albeit older than the one Swift ships with) or working to remove the ICU dependency altogether. We welcome ideas and contributions to this end.
