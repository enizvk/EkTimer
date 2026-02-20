// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EKTimer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "EKTimer",
            path: "Sources/EKTimer",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
