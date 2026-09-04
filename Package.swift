// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrayerCal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PrayerCal", targets: ["PrayerCal"])
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift.git", from: "1.4.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.9.6")
    ],
    targets: [
        .executableTarget(
            name: "PrayerCal",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift"),
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
        .testTarget(name: "PrayerCalTests", dependencies: ["PrayerCal"])
    ]
)
