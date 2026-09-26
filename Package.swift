// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Flux",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Flux", targets: ["Flux"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Flux",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Flux"
        ),
        .testTarget(
            name: "FluxTests",
            dependencies: ["Flux"],
            path: "Tests"
        )
    ]
)
