//
//  WeakWrapper.swift
//  Bricks
//
//  Created by Ido Rabin for Bricks on 30/10/2017.
//  Copyright © 2017 Bricks. All rights reserved.
//

import Foundation

import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("WeakWrapper")

// TODO: Determine if syntactically better? typealias WeakArray<T:AnyObject> = [Weak<T>]

//// This protocol will allow some collection manipulations
//public protocol Weakly<Value> where Value : AnyObject {
//    associatedtype Value: AnyObject
//}

public protocol Weakable {
    associatedtype Value : AnyObject
    var value : Value? { get }
}

/// A wrapper for weakly referenced objects, for use in observers arrays and other lists that require pointers to objects without retaining them
public class Weak<Value: AnyObject> : Weakable { // : Hashable, Equatable
    public typealias Value = Value
    
    public weak var value : Value?

    fileprivate init() {
        value = nil
    }

    public init (value: Value) {
        self.value = value
    }
    
    public convenience init?(value: Value?) {
        guard let value = value else {
            return nil
        }
        self.init(value: value)
    }

    static func newWeakArray(from values:[Value])->[Weak<Value>] {
        return values.compactMap { value in
            return Weak(value: value)
        }
    }
}

extension Weak : CustomStringConvertible {
    public var description: String {
        let classStr = "\(Self.self)".components(separatedBy: ".").last!
        return "\(classStr)(\(value.descOrNil)"
    }
}

extension Weak /* : Hashable */ where Value : Hashable {
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        if let val = value {
            hasher.combine(val)
        } else {
            // should not have hashValue 0 when value is nil, otherwise will crash sets and dictionaries
            hasher.combine(MemoryAddress(of: self).rawValue)
        }
    }
}

extension Weak : Equatable where Value : Equatable {
    
    // MARK: Equatable
    public static func ==(lhs:Weak<Value>, rhs:Weak<Value>)->Bool {
        return lhs.value == rhs.value
    }
    
    public static func ==(lhs:Weak<Value>, rhs:Value)->Bool {
        return lhs.value == rhs
    }
}

public extension Weak /* : Codable */ where Value : Codable {
    // MARK: Codable
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case value
    }

    convenience init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let val = try container.decode(Value.self, forKey: .value)
        // Otherwise, throws
        self.init()
        self.value = val
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.value, forKey: .value)
    }
}

//extension Sequence where Element : Weak<AnyObject> {
//    public var values : [Element.Value] {
//        return self.compactMap { $0.value }
//    }
//}

extension Sequence where Element : Weakable {
    public var values : [Element.Value] {
        return self.compactMap { $0.value }
    }
}

public extension Array where Element : Weak<AnyObject> {
    
    /// Mutate the array so that all nilified Weak elements are removed from it
    /// - Returns: count of elements that were of nil value and released
    @discardableResult
    mutating func compactNillifiedWeaks() ->Int {
        var result = 0
        for (index, item) in self.enumerated().reversed() {
            if item.value == nil {
                self.remove(at: index)
                result += 1
            }
        }
        return result
    }
    
    /// Mutate the array so that all nilified Weak elements are removed from it
    /// - Returns: count of elements that were of nil value and released
    mutating func invalidateNillifieds() ->Int {
        return self.compactNillifiedWeaks()
    }
}
