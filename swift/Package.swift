// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyProject",
    products: [
        .executable(
            name: "MyProject",
            targets: ["MyProject"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", .branch("main")),
    ],
    targets: [
        .executableTarget(
            name: "MyProject",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift"),
            ]
        ),
    ]
)
