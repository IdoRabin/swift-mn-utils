//
//  File.swift
//  
//
//  Created by Ido on 30/05/2023.
//

import Foundation

// IntEx
public extension Int {
    public var hex : String {
        return toHex()
    }
    public func toHex(uppercase:Bool? = false)->String {
        return Self.intToHex(value: self, uppercase:uppercase)
    }
    
    public static func intToHex(value:Int, uppercase:Bool? = false)->String {
        let hexStr = String(value, radix: 16, uppercase: uppercase)
        return hexStr
    }
}

public extension String {
    static func toHexString(int value:Int, uppercase:Bool? = false)->String {
        let hexStr = String(value, radix: 16, uppercase: uppercase)
    }
    
    static func toHexString(int64 value:Int64, uppercase:Bool? = false)->String {
        let hexStr = String(value, radix: 16, uppercase: uppercase)
    }
}
