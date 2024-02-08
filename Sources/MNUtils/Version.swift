//  Version.swift

// import AppKit

#if canImport(NIO)
import NIO
import CNIOAtomics
#endif

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
let MNUTILS_BUILD_NR : Int = 418
let MNUTILS_BUILD_VERSION = MNSemver (
    major: 0,
    minor: 2,
    patch: 0,
    prerelease: "\(PreRelease.alpha.rawValue)",
    metadata: [String(format: "0x%04X", MNUTILS_BUILD_NR)]
)
