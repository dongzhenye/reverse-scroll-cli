// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "reverse-scroll-cli",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ReverseScrollCLI",
            path: "Sources/ReverseScrollCLI"
        ),
        .testTarget(
            name: "ReverseScrollCLITests",
            dependencies: ["ReverseScrollCLI"],
            path: "Tests/ReverseScrollCLITests"
        ),
    ]
)
