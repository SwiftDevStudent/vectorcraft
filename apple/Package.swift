// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "VectorCraftCore",
  platforms: [.iOS(.v18), .macOS("27.0")],
  products: [
    .library(name: "VectorCraftCore", targets: ["VectorCraftCore"]),
    .executable(name: "VectorCraftMac", targets: ["VectorCraftMac"]),
    .executable(name: "VectorCraftScreenshots", targets: ["VectorCraftScreenshots"]),
  ],
  targets: [
    .executableTarget(name: "VectorCraftScreenshots", dependencies: ["VectorCraftCore"]),
    .systemLibrary(name: "CZlib"),
    .target(name: "VectorCraftCore", dependencies: ["CZlib"]),
    .executableTarget(
      name: "VectorCraftMac", dependencies: ["VectorCraftCore"],
      resources: [.process("Resources/Icons")]),
    .testTarget(name: "VectorCraftCoreTests", dependencies: ["VectorCraftCore"]),
    .testTarget(name: "VectorCraftMacTests", dependencies: ["VectorCraftMac", "VectorCraftCore"]),
    .testTarget(name: "VectorCraftScreenshotsTests", dependencies: ["VectorCraftScreenshots", "VectorCraftCore"]),
  ]
)
