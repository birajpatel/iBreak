// swift-tools-version: 6.4
// The Swift Tools Version of the package.

import PackageDescription

let package = Package(
    name: "iBreak",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "iBreak", targets: ["iBreak"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "iBreak",
            dependencies: [],
            path: "Sources/iBreak"
        )
        // Note: Tests are shell-based integration tests in Tests/iBreakTests/
        // Swift unit tests require full Xcode with XCTest framework support
    ]
)
