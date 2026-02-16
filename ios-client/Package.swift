// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MusicVisualizer",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MusicVisualizer",
            targets: ["MusicVisualizerCore"]
        ),
    ],
    dependencies: [
        // Add external dependencies here
    ],
    targets: [
        .target(
            name: "MusicVisualizerCore",
            path: "Sources",
            swiftSettings: [.define("USE_METAL")]
        ),
    ]
)
