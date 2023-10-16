//
//  WeakHashable.swift
//  
//
//  Created by Ido on 15/10/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("WeakHashable")

// TODO: Check why could Weak<any Hashable> do not seem to conform to Hahsable in the context of WeakSet - this will thus eliminate the need for class WeakHashable?
/// A wrapper for weakly referenced hashable objects, for use in observers arrays and other lists that require pointers to objects without retaining them
public class WeakHashable<Value: AnyObject & Hashable>  : Hashable, Equatable, Weakable {
    public typealias Value = Value
    
    public weak var value : Value?

    fileprivate init() {
        value = nil
    }

    public init (value: Value) {
        self.value = value
    }

    public init?(value: Value?) {
        guard let value = value else {
            return nil
        }
        self.value = value
    }
    
    static func newWeakArray(from values:[Value])->[Weak<Value>] {
        return values.compactMap { value in
            return Weak(value: value)
        }
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        if let val = value {
            hasher.combine(val.hashValue)
        } else {
            // should not have hashValue 0 when value is nil, otherwise will crash sets and dictionaries
            hasher.combine(MemoryAddress(of: self).rawValue)
        }
    }
    
    // MARK: Equatable
    public static func ==(lhs:WeakHashable<Value>, rhs:WeakHashable<Value>)->Bool {
        return lhs.value == rhs.value
    }
    
    public static func ==(lhs:WeakHashable<Value>, rhs:Value)->Bool {
        return lhs.value == rhs
    }
    
}

extension WeakHashable : CustomStringConvertible {
    public var description: String {
        let classStr = "\(Self.self)".components(separatedBy: ".").last!
        return "\(classStr)(\(value.descOrNil)"
    }
}
