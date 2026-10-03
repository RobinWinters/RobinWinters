// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EventSearchExample",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "EventSearchExample", targets: ["EventSearchExample"])],
    targets: [
        .target(name: "EventSearchExample"),
        .testTarget(name: "EventSearchExampleTests", dependencies: ["EventSearchExample"])
    ]
)
