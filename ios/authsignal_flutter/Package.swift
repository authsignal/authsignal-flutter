// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "authsignal_flutter",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(
      name: "authsignal-flutter",
      targets: ["authsignal_flutter"]
    )
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(
      url: "https://github.com/authsignal/authsignal-ios.git",
      .upToNextMinor(from: "2.13.1")
    )
  ],
  targets: [
    .target(
      name: "authsignal_flutter",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "Authsignal", package: "authsignal-ios")
      ]
    )
  ]
)
