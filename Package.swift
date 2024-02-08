// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MNUtils",
    platforms: [
        .macOS(.v13),
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MNUtils",
            targets: ["MNUtils"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        
        // 3rd party:
        .package(url: "https://github.com/apple/swift-log", from: "1.5.3"),
        
        // In-House pakcages

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        .target(
            name: "MNUtils",
            dependencies: [
                // 3rd party:
                .product(name: "Logging", package: "swift-log"),
                
                // In-House pakcages
                
            ],
            swiftSettings: [
                // Enables better optimizations when building in Release
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
                .define("PRODUCTION", .when(configuration: .release)),
                .define("DEBUG", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "MNUtilsTests",
            dependencies: ["MNUtils"],
            swiftSettings: [
                .define("PRODUCTION", .when(configuration: .release)),
                .define("DEBUG", .when(configuration: .debug)),
                .define("TESTING")
            ]
        ), // one
    ], // before
    
    swiftLanguageVersions: [.v5]
) // last
