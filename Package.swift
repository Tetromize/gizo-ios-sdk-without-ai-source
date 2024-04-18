// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GizoSDK-iOS",
        defaultLocalization: "en",

    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "GizoSDK-iOS",
            targets: ["GizoSDK-iOS"]),
    ],
    dependencies: [
    .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("10.12.3")),
    .package(name: "MapboxNavigation", url: "https://github.com/mapbox/mapbox-navigation-ios.git", .exact("2.12.0"))
    ],
    targets: [
        .target(
            name: "GizoSDK-iOS",
            path: "GizoSDK"),
            dependencies: ["MapboxMaps", "MapboxNavigation", "GizoSDK"],
            resources: [.copy("Gizo.bundle")],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
                .linkedLibrary("sqlite3"),
                .linkedFramework("CoreML"),
                .linkedFramework("SystemConfiguration")
            ]

    ],
    swiftLanguageVersions: [
        .v5
    ]
)