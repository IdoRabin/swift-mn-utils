//
//  UUUIEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public extension UUIDv5 {
    public var isZeroUID : Bool {
        return self.uuidString == UID_EMPTY_STRING
    }
    
    public var isEmpty : Bool {
        return self.isZeroUID
    }
    
    public static var empty : UUIDv5 {
        return UUIDv5(uuidString: UID_EMPTY_STRING)!
    }
}

extension UUID : JSONSerializable {
    
}

public extension UUID {
    public var shortDesc : String {
        return self.shortDescription
    }
    
    public var shortDescription : String {
        return self.description.substring(maxSize: 14, midIfClipped: "...")
    }
}
