// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PTReaderSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    .library(
      name: "PTReaderSwift",
      type: .dynamic,
      targets: ["PTReaderSwift"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.25.6"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
    .package(url: "https://github.com/mlalma/MLXUtilsLibrary.git", from: "0.0.5")
  ],
  targets: [
    .target(
      name: "PTReaderSwift",
      dependencies: [.product(name: "MLX", package: "mlx-swift"),
                     .product(name: "MLXNN", package: "mlx-swift"),
                     .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                     .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")]
    ),
    .testTarget(
      name: "PTReaderSwiftTests",
      dependencies: ["PTReaderSwift"],
      resources: [
       .copy("../../Resources/")
      ]
    ),
  ]
)
