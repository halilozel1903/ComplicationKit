// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ComplicationKit",
    platforms: [
        .watchOS(.v10),
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ComplicationKit", targets: ["ComplicationKit"]),
    ],
    targets: [
        .target(name: "ComplicationKit"),
        .testTarget(name: "ComplicationKitTests", dependencies: ["ComplicationKit"]),
    ]
)
