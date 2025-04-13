// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport // for macros support

let package = Package(
    name: "MNUtils",
    platforms: [
        .macOS(.v14), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)
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
        // DO NOT USE: .package(url: "https://github.com/apple/swift-log", from: "1.6.3"),
        
        // In-House pakcages
        //.package(url: "https://github.com/IdoRabin/swift-MNMacros", .upToNextMajor(from: "0.0.1-pre")),
        .package(path: "../../MNMacros"),
        
    ],
    targets: [
        .target(
            name: "MNUtils",
            dependencies: [
                // 3rd party:
                // DO NOT USE: .product(name: "Logging", package: "swift-log"),
                
                // In-House pakcages
                .product(name: "MNMacros", package: "MNMacros"),
                
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
