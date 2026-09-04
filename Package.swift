// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HijriBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HijriBar", targets: ["HijriBar"])
    ],
    targets: [
        .executableTarget(name: "HijriBar"),
        .testTarget(name: "HijriBarTests", dependencies: ["HijriBar"])
    ]
)
