//
//  SetEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.
//  Copyright © 2022 . All rights reserved.
//

import Foundation

public extension Set {
    
    
    /// Get all elements in the set as an array / sequence of the same type. Convenience, equivalent to let myArray = Array<Element>(mySet)
    ///
    /// - Returns: an array of the elements in the given set
    func allElements()->[Element] {
        return Array<Element>(self)
    }
    
    
}


