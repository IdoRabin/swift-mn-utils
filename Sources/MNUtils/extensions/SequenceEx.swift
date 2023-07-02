//
//  SequenceEx.swift
//  
//
//  Created by Ido on 16/07/2022.
//

import Foundation

public extension Sequence where Element == String {
    var descriptionLines : String {
        return self.joined(separator: "\n")
    }
    
    var descriptionJoined : String {
        return "[\(self.joined(separator: ", "))]"
    }
}

public extension Sequence where Element : CustomStringConvertible {
    var descriptionLines : String {
        let arr = self.map { item in
            return item.description
        }
        return arr.descriptionLines
    }
    
    var descriptionJoined : String {
        let arr = self.map { item in
            return item.description
        }
        return arr.descriptionJoined
    }
}
