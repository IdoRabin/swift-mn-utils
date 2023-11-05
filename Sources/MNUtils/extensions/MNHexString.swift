//
//  MNHexString.swift
//  
//
//  Created by Ido on 30/05/2023.
//

import Foundation

// IntEx
public extension Int {
    
    var hexString  : String {
        return toHex(uppercase: false)
    }
    
    func toHex(uppercase:Bool = false, prefix0x:Bool = false)->String {
        return Self.intToHex(value: self, uppercase:uppercase)
    }
    
    static func intToHex(value:Int, uppercase:Bool = false, prefix0x:Bool = false)->String {
        return (prefix0x ? "0x" : "") + String(value, radix: 16, uppercase: uppercase)
    }
}

public extension String {
    static func toHexString(int value:Int, uppercase:Bool = false)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
    
    func toHexString(int64 value:Int64, uppercase:Bool = false)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
}
