// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAssistiveTouch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacAssistiveTouch",
            targets: ["MacAssistiveTouch"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacAssistiveTouch",
            path: "Sources/MacAssistiveTouch",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
