//
//  DateEx.swift
//  Date extensions
//
//  Created by Ido on 28/08/2022.
//

import Foundation

public extension Date /* isInTheFuture/Past */ {
    
    // MARK: Properties:
    var isInTheFuture : Bool {
        return self.isInTheFuture(safetyMargin: 0)
    }
    
    var isInThePast : Bool {
        return self.isInThePast(safetyMargin: 0)
    }
    
    func isInTheFuture(safetyMargin:TimeInterval)->Bool {
        return self.timeIntervalSinceNow  > safetyMargin
    }
    
    func isInThePast(safetyMargin:TimeInterval)->Bool {
        return self.timeIntervalSinceNow  < -safetyMargin
    }
}

public extension Date /* is near another Date */ {
    // MARK: Static funcs
    static func isDatesAreNear(date1:Date?, date2:Date?, tolerance:TimeInterval = Date.SECONDS_IN_A_MINUTE) -> Bool {
        
        if let date1 = date1, let date2 = date2 {
            // Case: both dates are not nil
            
            let delta = date1.timeIntervalSince1970 - date2.timeIntervalSince1970
            return abs(delta) <= tolerance
            
        } else if (date1 == nil && date2 != nil) ||
                    (date1 != nil && date2 == nil) {
            // Case: One date is nil and the other is not!
            return false
        } else {
            // Case: Both dates are nil
            return false
        }
    }
    
    func isNear(other:Date?, tolerance:TimeInterval = Date.SECONDS_IN_A_MINUTE) -> Bool {
        return Self.isDatesAreNear(date1: self, date2: other, tolerance: tolerance)
    }
}
