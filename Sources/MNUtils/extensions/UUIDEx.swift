//
//  File.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation

public extension UUID {
    var isZeroUID : Bool {
        return self.uuidString == UID_EMPTY_STRING
    }
    
    var isEmpty : Bool {
        return self.isZeroUID
    }
    
    static var empty : UUID {
        return UUID(uuidString: UID_EMPTY_STRING)!
    }
}
