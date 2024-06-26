//
//  MNSemver.swift
//
//
//  Source: https://github.com/sersoft-gmbh/semver/blob/master/Sources/SemVer/Version.swift
//

import Foundation
import struct Foundation.CharacterSet

public extension CharacterSet {
    /// Contains the allowed characters for a Version suffix (Version.prelease and Version.metadata)
    /// Allowed are alphanumerics and hyphen.
    static let versionSuffixAllowed: CharacterSet = {
        var validCharset = alphanumerics
        validCharset.insert("-")
        return validCharset
    }()
}

public typealias MNSemver = Semver

/// A Version struct that implements the rules of semantic versioning.
/// - SeeAlso: https://semver.org
public struct Semver: Hashable, Comparable, LosslessStringConvertible {
    /// The major part of this version. Must be >= 0.
    public var major: Int {
        willSet { assert(newValue >= 0) }
    }
    /// The minor part of this version. Must be >= 0.
    public var minor: Int {
        willSet { assert(newValue >= 0) }
    }
    /// The patch part of this version. Must be >= 0.
    public var patch: Int {
        willSet { assert(newValue >= 0) }
    }
    /// The prelease part of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    /// - SeeAlso: `CharacterSet.versionSuffixAllowed`
    public var prerelease: String {
        willSet { assert(CharacterSet(charactersIn: newValue).isSubset(of: .versionSuffixAllowed)) }
    }
    /// The metadata of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    /// - SeeAlso: `CharacterSet.versionSuffixAllowed`
    public var metadata: Array<String> {
        willSet {
            assert(newValue.allSatisfy { !$0.isEmpty && CharacterSet(charactersIn: $0).isSubset(of: .versionSuffixAllowed) })
        }
    }

    /// inherited
    @inlinable
    public var description: String { versionString() }

    /// Creates a new version with the given parts.
    ///
    /// - Parameters:
    ///   - major: The major part of this version. Must be >= 0.
    ///   - minor: The minor part of this version. Must be >= 0.
    ///   - patch: The patch part of this version. Must be >= 0.
    ///   - prerelease: The prelease part of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    ///   - metadata: The metadata of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    public init(major: Int, minor: Int = 0, patch: Int = 0, prerelease: String = "", metadata: Array<String> = .init()) {
        assert(major >= 0)
        assert(minor >= 0)
        assert(patch >= 0)
        assert(CharacterSet(charactersIn: prerelease).isSubset(of: .versionSuffixAllowed))
        assert(metadata.allSatisfy { !$0.isEmpty && CharacterSet(charactersIn: $0).isSubset(of: .versionSuffixAllowed) })

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.metadata = metadata
    }

    /// Creates a new version with the given parts.
    ///
    /// - Parameters:
    ///   - major: The major part of this version. Must be >= 0.
    ///   - minor: The minor part of this version. Must be >= 0.
    ///   - patch: The patch part of this version. Must be >= 0.
    ///   - prerelease: The prelease part of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    ///   - metadata: The metadata of this version. Must only contain caracters in `CharacterSet.versionSuffixAllowed`.
    @inlinable
    public init(major: Int, minor: Int = 0, patch: Int = 0, prerelease: String = "", metadata: String...) {
        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease, metadata: metadata)
    }

    /// inherited
    public init?(_ description: String) {
        guard !description.isEmpty &&
              description.range(of: #"^([0-9]+\.){0,2}[0-9]+(-[0-9A-Za-z-]+)?(\+([0-9A-Za-z-]+\.?)*)?$"#, options: .regularExpression) != nil
        else { return nil }

        // This should be fine after above's regular expression
        let idx = description.range(of: #"[0-9](\+|-)"#, options: .regularExpression).map { description.index(before: $0.upperBound) } ?? description.endIndex
        var parts: Array<String> = description[..<idx].components(separatedBy: ".").reversed()
        guard (1...3).contains(parts.count),
              let major = parts.popLast().flatMap(Int.init)
        else { return nil }
        let minor = parts.popLast().flatMap(Int.init) ?? 0
        let patch = parts.popLast().flatMap(Int.init) ?? 0

        let prerelease: String
        if let searchRange = description.range(of: #"(^|\.)[0-9]+-[0-9A-Za-z-]+(\+|$)"#, options: .regularExpression),
           case let substr = description[searchRange],
           let range = substr.range(of: "[0-9]-[0-9A-Za-z-]+", options: .regularExpression) {
            prerelease = String(substr[substr.index(range.lowerBound, offsetBy: 2)..<range.upperBound])
        } else {
            prerelease = ""
        }

        let metadata: Array<String>
        if let range = description.range(of: #"\+([0-9A-Za-z-]+\.?)+$"#, options: .regularExpression) {
            let metadataString = description[description.index(after: range.lowerBound)..<range.upperBound]
            metadata = metadataString.components(separatedBy: ".")
        } else {
            metadata = .init()
        }

        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease, metadata: metadata)
    }

    /// inherited
    public func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
        hasher.combine(prerelease)
        // metadata does not participate in hashing and equating
    }

    /// Creates a version string using the given options.
    ///
    /// - Parameter options: The options to use for creating the version string.
    /// - Returns: A string containing the version formatted with the given options.
    public func versionString(formattedWith options: FormattingOptions = .fullVersion) -> String {
        var versionString = String(major)
        if !options.contains(.dropPatchIfZero) || patch != 0 {
            versionString += ".\(minor).\(patch)"
        } else if !options.contains(.dropMinorIfZero) || minor != 0 {
            versionString += ".\(minor)"
        }
        if options.contains(.includePrerelease) && !prerelease.isEmpty {
            versionString += "-\(prerelease)"
        }
        if options.contains(.includeMetadata) && !metadata.isEmpty {
            versionString += "+\(metadata.joined(separator: "."))"
        }
        return versionString
    }
}

/* This currently does not work, due to the compiler ignoring the `init(_ description:)` for `Version("blah")` now.
// MARK: - String Literal Conversion
/// - Note: This conformance will crash if the given String literal is not a valid version!
 public extension Version: ExpressibleByStringLiteral {
    /// inherited
    public typealias StringLiteralType = String

    /// inherited
    public init(stringLiteral value: StringLiteralType) {
        guard let version = Self.init(value) else {
            fatalError("'\(value)' is not a valid semantic version!")
        }
        self = version
    }
}
*/

// MARK: - Comparison
public extension Semver {
    /// inherited
    static func ==(lhs: Semver, rhs: Semver) -> Bool {
        (lhs.major, lhs.minor, lhs.patch, lhs.prerelease)
            ==
        (rhs.major, rhs.minor, rhs.patch, rhs.prerelease)
    }

    /// inherited
    static func <(lhs: Semver, rhs: Semver) -> Bool {
        (lhs.major, lhs.minor, lhs.patch)
            <
        (rhs.major, rhs.minor, rhs.patch)
            || // A version with a prerelease has a lower precedence than the same without
        ((!lhs.prerelease.isEmpty && rhs.prerelease.isEmpty) || (lhs.prerelease < rhs.prerelease))
    }

    /// inherited
    static func >(lhs: Semver, rhs: Semver) -> Bool {
        (lhs.major, lhs.minor, lhs.patch)
            >
        (rhs.major, rhs.minor, rhs.patch)
            || // A version with a prerelease has a lower precedence than the same without
        ((lhs.prerelease.isEmpty && !rhs.prerelease.isEmpty) || (lhs.prerelease > rhs.prerelease))
    }
}

// MARK: - Incrementing
public extension Semver {
    /// Lists all the numeric parts of a version (major, minor and patch).
    enum NumericPart: Hashable, CustomStringConvertible {
        /// The major version part.
        case major
        /// The minor version part.
        case minor
        /// The patch version part.
        case patch

        /// inherited
        public var description: String {
            switch self {
            case .major: return "major"
            case .minor: return "minor"
            case .patch: return "patch"
            }
        }
    }

    /// Returns the next version, increasing the given numeric part, respecting any associated rules:
    /// - If the major version is increased, minor and patch are set to 0.
    /// - If the minor version is increased, patch is set to 0
    /// - If the patch version is increased, no other changes are made.
    ///
    /// - Parameters:
    ///   - part: The numeric part to increase.
    ///   - keepingMetadata: Whether or not the metadata should be kept. Defaults to `false`.
    /// - Returns: A new version that has the specified `part` increased, along with the necessary other changes.
    func next(_ part: NumericPart, keepingMetadata: Bool = false) -> Semver {
        let newMetadata = keepingMetadata ? metadata : []
        switch part {
        case .major: return Semver(major: major + 1, minor: 0, patch: 0, metadata: newMetadata)
        case .minor: return Semver(major: major, minor: minor + 1, patch: 0, metadata: newMetadata)
        case .patch: return Semver(major: major, minor: minor, patch: patch + 1, metadata: newMetadata)
        }
    }

    /// Increases the given numeric part of the version, respecting any associated rules:
    /// - If the major version is increased, minor and patch are set to 0.
    /// - If the minor version is increased, patch is set to 0
    /// - If the patch version is increased, no other changes are made.
    ///
    /// - Parameters:
    ///   - part: The numeric part to increase.
    ///   - keepingMetadata: Whether or not the metadata should be kept. Defaults to `false`.
    mutating func increase(_ part: NumericPart, keepingMetadata: Bool = false) {
        switch part {
        case .major:
            major += 1
            (minor, patch) = (0, 0)
        case .minor:
            minor += 1
            patch = 0
        case .patch:
            patch += 1
        }
        if !keepingMetadata {
            metadata.removeAll()
        }
    }
}

// MARK: - Formatting Options
public extension Semver {
    /// Describes a set options that define the formatting behavior.
    @frozen
    struct FormattingOptions: OptionSet {
        /// inherited
        public typealias RawValue = Int

        /// inherited
        public let rawValue: RawValue

        /// inherited
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

public extension Semver.FormattingOptions {
    /// Leave out patch part if it's zero.
    static let dropPatchIfZero = Semver.FormattingOptions(rawValue: 1 << 0)
    /// Leave out minor part if it's zero. Requires `dropPatchIfZero`.
    static let dropMinorIfZero = Semver.FormattingOptions(rawValue: 1 << 1)
    /// Include the prerelease part of the version.
    static let includePrerelease = Semver.FormattingOptions(rawValue: 1 << 2)
    /// Include the metadata part of the version.
    static let includeMetadata = Semver.FormattingOptions(rawValue: 1 << 3)

    /// Combination of `.includePrerelease` and `.includeMetadata`.
    @inlinable
    static var fullVersion: Semver.FormattingOptions { [.includePrerelease, .includeMetadata] }
    /// Combination of `.dropPatchIfZero` and `.dropMinorIfZero`.
    @inlinable
    static var dropTrailingZeros: Semver.FormattingOptions { [.dropMinorIfZero, .dropPatchIfZero] }
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension Semver: Sendable {}
extension Semver.NumericPart: Sendable {}
extension Semver.FormattingOptions: Sendable {}
#endif
