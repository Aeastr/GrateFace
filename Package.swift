// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GrateFace",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v26)],
    products: [.library(name: "GrateFace", targets: ["GrateFace"])],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.20"))
    ],
    targets: [
        .target(name: "GrateFace", dependencies: ["ZIPFoundation"],
                resources: [.copy("Resources/Photos27Seed.watchface")])
    ]
)
