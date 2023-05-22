//
//  DateEx.swift
//  Date extensions
//
//  Created by Ido on 28/08/2022.
//

import Foundation

extension Date {
    
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
