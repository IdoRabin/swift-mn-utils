//
//  OptionSetEx.swift
//  grafo
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public extension OptionSet where RawValue: FixedWidthInteger {
    
    // MARK: Private
    @inline(__always)
    private func isPowerOfTwo(_ n: RawValue) -> Bool {
        return (n > 0) && (n & (n - 1) == 0)
    }
    
    // MARK: Properties / members
    /// Returns all elements possible in the set as a Sequence, like allElements of an Enum.
    static var allElements :  [Self] {
        var val : RawValue = 0
        var result : [Self] = []
        while val < 256 {
            let bits : RawValue = 1 << val
            if let resultElement = Self(rawValue: bits) {
                result.append(resultElement)
            } else {
                break
            }
            val += 1
        }
        
        if val >= 256 {
            print("OptionSetEx.allElements goes up to 256 and no more")
        }
        return result
    }
    
    public var elementsCount : Int {
        guard isPowerOfTwo(self.rawValue) else {
            return 1 // one element when we are an exact power of 2
        }
        
        return Array(self.elements).count
    }
    
    /// Returns all the elements in the current set as a Sequence
    public var elements : AnySequence<Self> {
        
        // TODO: Check how to implement this optimization returning a sequence
        // guard isPowerOfTwo(self.rawValue) else {
        //     return ???
        // }
        
        var remainingBits = rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            return AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
    
    // MARK: Public
    /// Checks for intersection between the current set and another set, syntactic sugar
    /// - Parameter members: sequence of member elements
    /// - Returns: true if at least one element in common between self and anyOf other members
    public func contains(anyOf members: [Element]) -> Bool {
        return !self.intersection(Self(members)).isEmpty
    }
    
    // Syntactic sugar
    
    /// Checks for intersection between the current set and another set, syntactic sugar
    /// - Parameter other: another optionSet of the same type
    /// - Returns: true if at least one element in common between self and anyOf the other set.
    public func contains(anyOf other: Self) -> Bool {
        return !self.intersection(other).isEmpty
    }
}
