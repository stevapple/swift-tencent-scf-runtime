// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MyCloudFunction",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "MyCloudFunction", targets: ["MyCloudFunction"]),
    ],
    dependencies: [
        // This is the dependency on the swift-tencent-scf-runtime library.
        // In real-world projects this would say:
        // .package(url: "https://github.com/stevapple/swift-tencent-scf-runtime", from: "0.2.0")
        .package(name: "swift-tencent-scf-runtime", path: "../../.."),
        .package(name: "Shared", path: "../Shared"),
    ],
    targets: [
        .executableTarget(
            name: "MyCloudFunction", dependencies: [
                .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
                .product(name: "Shared", package: "Shared"),
            ]
        ),
    ]
)
