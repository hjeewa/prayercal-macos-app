// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrayerCal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PrayerCal", targets: ["PrayerCal"])
    ],
    targets: [
        .executableTarget(name: "PrayerCal"),
        .testTarget(name: "PrayerCalTests", dependencies: ["PrayerCal"])
    ]
)
