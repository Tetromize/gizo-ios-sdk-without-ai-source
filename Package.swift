// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GizoSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "GizoSDK",
            targets: ["GizoSDK"]),
    ],
    dependencies: [
    .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("10.12.3")),
    .package(name: "MapboxNavigation", url: "https://github.com/mapbox/mapbox-navigation-ios.git", .exact("2.12.0"))
    ],
    targets: [
        .target(
            name: "GizoSDK",
            path: "GizoSDK"),
            dependencies: ["MapboxMaps", "MapboxNavigation"],

    ],
    swiftLanguageVersions: [
        .v5
    ]
)