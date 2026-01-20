// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenCodeMenuApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OpenCodeMenuApp",
            targets: ["OpenCodeMenuApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .executableTarget(
            name: "OpenCodeMenuApp",
            dependencies: ["OpenCodeMenuAppCore"],
            path: "Sources",
            exclude: [
                "App",
                "Models",
                "Services",
                "ViewModels",
                "Views",
                "Windows"
            ],
            sources: ["OpenCodeMenuApp.swift"],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit")
            ]
        ),
        .target(
            name: "OpenCodeMenuAppCore",
            dependencies: ["KeychainAccess"],
            path: "Sources",
            exclude: ["OpenCodeMenuApp.swift"],
            sources: [
                "App",
                "Models",
                "Services",
                "ViewModels",
                "Views",
                "Windows"
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit")
            ]
        ),
    ]
)
