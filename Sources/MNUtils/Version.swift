//  Version.swift

import AppKit

enum PreRelease: String {
    case none = ""
    case alpha = "alpha"
    case beta = "beta"
    case RC = "RC"
}

// https://semver.org/
// Swift package PackageDescription also supports Sever2 Version struct defined, but we will be using ver 1.0.0

// Hard coded app version:
let MNUTILS_NAME_STR : String = "MNUtils"

// String fields allow only alphanumerics and a hyphen (-)
let MNUTILS_BUILD_NR : Int = 1717
let MNUTILS_BUILD_VERSION = SemVer(
    major: 0,
    minor: 1,
    patch: 0,
    prerelease: "\(PreRelease.alpha.rawValue)",
    metadata: [String(format: "%04X", MNUTILS_BUILD_NR)]
)

