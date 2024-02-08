//
//  WeakWithMemAddr.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging // we chose this because of nio server logging implications

fileprivate let dlog : Logger? = Logger(label: "WeakWithMemAddr")

/// A wrapper for weakly referenced objects, specialining in the case where equality or hashing values equal, but memory adresses differ
public class WeakWithMemAddr<Value : AnyObject> : Weak<Value> {
    let memoryAdress : MemoryAddress<Value>

    override init(value: Value) {
        self.memoryAdress = MemoryAddress(of: value)
        super.init(value: value)
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.memoryAdress.rawValue)
        if let val = value as? any Hashable {
            hasher.combine(val)
        }
    }
    
    // MARK: Equatable
    public static func ==(lhs:WeakWithMemAddr<Value>, rhs:WeakWithMemAddr<Value>)->Bool {
        return lhs.memoryAdress.rawValue == rhs.memoryAdress.rawValue
    }
    
    public static func ==(lhs:WeakWithMemAddr<Value>, rhs:Value)->Bool {
        return lhs.memoryAdress == MemoryAddress(of: rhs)
    }
    
    public static func ==(lhs:WeakWithMemAddr<Value>, rhs:Weak<Value>)->Bool {
        guard let rval = rhs.value else {
            return lhs.value == nil
        }
        
        return lhs.memoryAdress == MemoryAddress(of: rval)
    }
}

class WeakWithMemAddrSet<T: AnyObject, WeakType: WeakWithMemAddr<T>> : WeakSet<T, WeakType> where T : Equatable & Hashable {
    typealias WeakedT = WeakWithMemAddr<T>
}
