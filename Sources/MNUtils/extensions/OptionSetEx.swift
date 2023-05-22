//
//  OptionSetEx.swift
//  grafo
//
//  Created by Ido on 25/06/2023.
//

import Foundation

public extension OptionSet where RawValue: FixedWidthInteger {

    static var allElements :  [Self] {
        var val : RawValue = 0
        var result : [Self] = []
        while val < 128 {
            let bits : RawValue = 1 << val
            if let resultElement = Self(rawValue: bits) {
                result.append(resultElement)
            } else {
                break
            }
            val += 1
        }
        return result
    }
    
    var elements : AnySequence<Self> {
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
}
