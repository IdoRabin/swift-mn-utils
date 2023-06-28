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


///// A wrapper for weakly referenced objects, for use in observers arrays and other lists that require pointers to objects without retaining them
public class Weak<Value: AnyObject> {
    public weak var value : Value?
    
    fileprivate init() {
        value = nil
    }
    
    public init (value: Value) {
        self.value = value
    }
    
    static func newWeakArray(from values:[Value])->[Weak<Value>] {
        return values.compactMap { value in
            return Weak(value: value)
        }
    }
}

public extension Weak /* : Codable */ where Value : Codable {
    // MARK: Codable
    private enum CodingKeys : String, CodingKey {
        case value
    }
    
    convenience init (from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
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

//public extension Weak /* : Codable */ where Value : Identifiable, Value.ID : Codable {
//    // MARK: Codable
//    private enum CodingKeysIdeable : String, CodingKey {
//        case id
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeysIdeable.self)
//        try container.encodeIfPresent(self.value?.id, forKey: .id)
//    }
//
//    convenience init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeysIdeable.self)
//        guard let id = try container.decodeIfPresent(Value.ID.self, forKey: .id) else {
//            throw MNError(code:.misc_failed_decoding, reason: "failed decoding id of Weak<\(Value.self)> where id tpye: \(Value.ID.self)")
//        }
//
//        // Otherwise, throws
//        self.init()
//
//        dlog?.warning("TODO: Continue with decoding id : \(Value.ID.self) = \(id). Find or instantiate owner and attach.")
//        // self.value?.id = id
//    }
//}


typealias WeakArray<T:AnyObject> = [Weak<T>]

/*
public class WeakIdentifiable<Value: AnyObject & Identifiable> : Codable where Value.ID : LosslessStringConvertible {
    
}

public class WeakIdentifiable<Value: AnyObject & Identifiable> : Codable where Value.ID : Codable {
    public weak var value : Value?
    
    public init (value: Value) {
        self.value = value
    }
    
    static func newWeakArray(from values:[Value])->[Weak<Value>] {
        return values.compactMap { value in
            return Weak(value: value)
        }
    }
    
    
}
*/
//
//// This protocol will allow some
//public protocol Weakly {
//    associatedtype Value: AnyObject
//    var weak: Weak<Value> { get }
//}
//
//extension Weak : Equatable where Value : Equatable {
//    public static func == (lhs: Weak<Value>, rhs: Weak<Value>) -> Bool {
//        return lhs.value == rhs.value
//    }
//}
//
//extension Weak: Weakly {
//    public var weak: Weak<Value> { return self }
//}
//
//public extension Dictionary where Key : Weak<AnyObject> {
//    
//    /// Reaps and removes all wrapped references that were released and now point at null
//    /// NOTE: Do not call this during iterations, since the indexes and amount of items change -
//    mutating func invalidate() {
//        self = self.filter { nil != $0.key.value }
//    }
//}
//
//public extension Dictionary where Value : Weak<AnyObject> {
//    
//    /// Reaps and removes all wrapped references that were released and now point at null
//    /// NOTE: Do not call this during iterations, since the indexes and amount of items change -
//    mutating func invalidate() {
//        self = self.filter { nil != $0.value.value }
//    }
//}
//
//public extension Array where Element : Weakly /* Same as Weak<T> where T is one specific class inheriting from AnyObject */ {
//    
//    /// Reaps and removes all wrapped references that were released and now point at null
//    /// NOTE: Do not call this during iterations, since the indexes and amount of items change -
//    /// - Returns: true if at least one item was invalid (weak released), false if no item was removed
//    mutating func invalidate()->Bool {
//        var removedCnt = 0
//        
//        self = self.filter { item in
//            if item.weak.value != nil {
//                return true
//            } else {
//                removedCnt += 1
//                return false
//            }
//        }
//        
//        return removedCnt > 0
//    }
//    
//    /// Returns an array of all the wrapped values in the array of Weak containers
//    /// - Returns: array of the values of each of the Wear<> wrappers.
//    func wrappedValues()->[Element.Value]  {
//        return self.compactMap{ $0.weak.value }
//    }
//}
//
//
///// A wrapper for weakly binded objects, for use in observers arrays and other lists that require pointers to objects without retaining them
///// This class is Hashable, and therefore can be used in dictionaries and two-way dictionaries
//public class WeakWrapperHashable<T:HashableObject> : Hashable
//{
//    weak var value: T?
//    
//    
//    /// Initializer
//    ///
//    /// - Parameter value: Any object that is retainable will be wrapped by this instance, as a weak reference
//    init(value: T) {
//        self.value = value
//    }
//    
//    /// Initializer
//    ///
//    /// - Parameter value: Any object that is retainable will be wrapped by this instance, as a weak reference
//    init(_ value: T) {
//        self.value = value
//    }
//    
//    /// Returns the hash value for the weakly retained object
//    public func hash(into hasher: inout Hasher) {
//        if let val = value {
//            hasher.combine(val.hashValue)
//        }
//    }
//    
//    /// Equate
//    ///
//    /// - Parameters:
//    ///   - lhs: left hand side parameter
//    ///   - rhs: right hand side parameter
//    /// - Returns: Will return true when both parameters are "equal" by comparing their hash values
//    public static func ==(lhs: WeakWrapperHashable, rhs: WeakWrapperHashable) -> Bool {
//        if let l = lhs.value, let r = rhs.value {
//            return l == r
//        }
//        
//        return false
//    }
//}
