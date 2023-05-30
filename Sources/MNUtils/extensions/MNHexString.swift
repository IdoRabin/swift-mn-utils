//
//  MNHexString.swift
//  
//
//  Created by Ido on 30/05/2023.
//

import Foundation

fileprivate static let DEFAULT_UPPERCASE_HEX = false

// IntEx
public extension Int {
    
    var hexString  : String {
        return toHex(uppercase: DEFAULT_UPPERCASE_HEX)
    }
    
    func toHex(uppercase:Bool = DEFAULT_UPPERCASE_HEX)->String {
        return Self.intToHex(value: self, uppercase:uppercase)
    }
    
    static func intToHex(value:Int, uppercase:Bool = DEFAULT_UPPERCASE_HEX)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
}

public extension String {
    static func toHexString(int value:Int, uppercase:Bool = DEFAULT_UPPERCASE_HEX)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
    
    func toHexString(int64 value:Int64, uppercase:Bool = DEFAULT_UPPERCASE_HEX)->String {
        return String(value, radix: 16, uppercase: uppercase)
    }
}
