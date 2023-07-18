//
//  File.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation

public extension UUIDv5 {
    var isZeroUID : Bool {
        return self.uuidString == UID_EMPTY_STRING
    }
    
    var isEmpty : Bool {
        return self.isZeroUID
    }
    
    static var empty : UUIDv5 {
        return UUIDv5(uuidString: UID_EMPTY_STRING)!
    }
}
