//
//  MNHexString.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

// IntEx
public extension BinaryInteger {
    
    var hexString  : String {
        return toHex(uppercase: false)
    }
    
    func toHex(uppercase:Bool = false, prefix0x:Bool = false)->String {
        return Self.intToHex(value: self, uppercase:uppercase)
    }
    
    static func intToHex(value:Self, uppercase:Bool = false, prefix0x:Bool = false)->String {
        return (prefix0x ? "0x" : "") + String(value, radix: 16, uppercase: uppercase)
    }
}

public extension String {
    
    static func toHexString(int value:any BinaryInteger, uppercase:Bool = false)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
    
    func toHexString(int64 value:any BinaryInteger, uppercase:Bool = false)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
}
