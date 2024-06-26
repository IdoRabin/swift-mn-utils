//
//  String+PathComponents.swift
//  rabac-test-project
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation



#if VAPOR || canImport(Vapor) || canImport(RoutingKit)
// This is implemented in the package RoutingKit which Vapor frameowrk is dependent on / sdk: see framework RoutingKit/Sources/RoutingKit/PathComponent.swift
    import RoutingKit
#else
// We implement a complimentary extension for when Vapor is absent
/// A single path component of a `Route`. An array of these components describes
/// a route's path, including which parts are constant and which parts are dynamic.
public enum PathComponent: ExpressibleByStringInterpolation, CustomStringConvertible {
    /// A normal, constant path component.
    case constant(String)

    /// A dynamic parameter component.
    ///
    /// The supplied identifier will be used to fetch the associated
    /// value from `Parameters`.
    ///
    /// Represented as `:` followed by the identifier.
    case parameter(String)
    
    /// A dynamic parameter component with discarded value.
    ///
    /// Represented as `*`
    case anything
    
    /// A fallback component that will match one *or more* dynamic
    /// parameter components with discarded values.
    ///
    /// Catch alls have the lowest precedence, and will only be matched
    /// if no more specific path components are found.
    ///
    /// The matched subpath will be stored into `Parameters.catchall`.
    ///
    /// Represented as `**`
    case catchall

    /// `ExpressibleByStringLiteral` conformance.
    // Is included in the RoutingKit package
    public init(stringLiteral value: String) {
        if value.hasPrefix(":") {
            self = .parameter(.init(value.dropFirst()))
        } else if value == "*" {
            self = .anything
        } else if value == "**" {
            self = .catchall
        } else {
            self = .constant(value)
        }
    }
    
    /// `CustomStringConvertible` conformance.
    public var description: String {
        switch self {
        case .anything:
            return "*"
        case .catchall:
            return "**"
        case .parameter(let name):
            return ":" + name
        case .constant(let constant):
            return constant
        }
    }
}

// Regardless of Vapor being imported or not:
// extending Vapor RoutingKit PathComponent
extension PathComponent : Codable, Hashable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(stringLiteral: string)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.description)
    }
    
    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.description == rhs.description
    }
}


public extension String /* path components */ {
    var asPathComponents : [PathComponent] {
        return self.components(separatedBy: "/").map { str in
            return PathComponent(stringLiteral: str)
        }
    }
}

#endif

/// ========================= regardless of implementation =====================================

public extension Sequence where Element == PathComponent {
    var fullPath:String {
        return "/" + self.descriptions().joined(separator: "/")
    }
}

public extension Array where Element == PathComponent {
    var fullPath:String {
        return self.map { elem in
            "\(elem)"
        }.joined(separator: "/")
        
        // We hate $0 notation!
        // return self.map { "\($0)" }.joined(separator: "/")
    }
}
