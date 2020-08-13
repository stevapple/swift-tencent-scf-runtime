// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "MyCloudFunction",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "MyCloudFunction", targets: ["MyCloudFunction"]),
    ],
    dependencies: [
        // This is the dependency on the swift-tencent-scf-runtime library.
        // In real-world projects this would say:
        // .package(url: "https://github.com/stevapple/swift-tencent-scf-runtime.git", from: "0.0.3")
        .package(name: "swift-tencent-scf-runtime", path: "../../.."),
        .package(name: "Shared", path: "../Shared"),
    ],
    targets: [
        .target(
            name: "MyCloudFunction", dependencies: [
                .product(name: "TencentSCFRuntime", package: "swift-tencent-scf-runtime"),
                .product(name: "Shared", package: "Shared"),
            ]
        ),
    ]
)
