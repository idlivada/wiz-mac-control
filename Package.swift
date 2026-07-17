// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WizControl",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WizControl",
            path: "Sources/WizControl"
        )
    ]
)
