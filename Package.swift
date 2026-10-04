// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TapFlow",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TapFlow", targets: ["TapFlow"])],
    targets: [
        .executableTarget(name: "TapFlow"),
        .testTarget(name: "TapFlowTests", dependencies: ["TapFlow"])
    ]
)
