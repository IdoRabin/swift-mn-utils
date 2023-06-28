//
//  DateComponentsEx.swift
//  
//
//  Created by Ido on 18/06/2023.
//

import Foundation

public extension Calendar.Component {
    static var all = Set<Calendar.Component>([.era, .year, .month, .day, .hour, .minute, .second])
}

public extension Calendar {
    func componentsOf(duration:TimeInterval) -> DateComponents {
        return self.dateComponents(Calendar.Component.all,
                                   from:Date.now,
                                   to:Date.now.addingTimeInterval(duration))
    }
    
    func componentsOf(timeIntervalSince1970:TimeInterval) -> DateComponents {
        return self.componentsOf(date: Date(optionalTimeIntervalSince1970: timeIntervalSince1970)!)
    }
    
    func componentsOf(date:Date) -> DateComponents {
        return self.dateComponents(Calendar.Component.all, from: date)
    }
}
