// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-tencent-scf-runtime-samples",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        // Introductory example.
        .executable(name: "HelloWorld", targets: ["HelloWorld"]),
        // Good for benchmarking.
        .executable(name: "Benchmark", targets: ["Benchmark"]),
        // Demonstrate different types of error handling.
        .executable(name: "ErrorHandling", targets: ["ErrorHandling"]),
        // Demostrate how to integrate with API Gateway.
        .executable(name: "APIGateway", targets: ["APIGateway"]),
        // Fully featured example with domain specific business logic.
        .executable(name: "CurrencyExchange", targets: ["CurrencyExchange"]),
    ],
    dependencies: [
        // This is the dependency on the swift-tencent-scf-runtime library.
        // In real-world projects, this would say:
        // .package(url: "https://github.com/stevapple/swift-tencent-scf-runtime.git", from: "1.0.0")
        .package(name: "swift-tencent-scf-runtime", path: "../.."),
    ],
    targets: [
        .target(name: "HelloWorld", dependencies: [
            .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
        ]),
        .target(name: "Benchmark", dependencies: [
            .product(name: "TencentSCFRuntimeCore", package: "swift-tencent-scf-runtime"),
        ]),
        .target(name: "ErrorHandling", dependencies: [
            .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
        ]),
        .target(name: "APIGateway", dependencies: [
            .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
            .product(name: "TencentSCFEvents", package: "swift-tencent-scf-runtime"),
        ]),
        .target(name: "CurrencyExchange", dependencies: [
            .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
        ]),
    ]
)
