//
//  CustomStringConvertibleEx.swift
//  Bricks
//
// Created by Ido Rabin for Bricks on 17/1/2024.
// Copyright © 2024 Bricks. All rights reserved.
//

import Foundation

//public extension CustomStringConvertible {
//    var description : String {
//        get {
//            return String(describing: self)
//        }
//    }
//}

public extension Set where Element : CustomStringConvertible {
    
    var description : String {
        get {
            return self.allElements().description
        }
    }
    
    var descriptionLines : String {
        get {
            return self.allElements().descriptionLines
        }
    }
    
    var descriptionsJoined : String {
        get {
            return self.allElements().descriptionsJoined
        }
    }
}

public extension Array where Element : CustomStringConvertible {
    var description : String {
        get {
            var result : String = ""
            forEachIndex { (index, element) in
                result.append(element.description)
                if (index != self.count - 1) {
                    result.append(",")
                }
            }
            return "[\(result)]"
        }
    }
    
    var descriptionLines : String {
        get {
            var result : String = ""
            if self.count > 0 {
                self.forEachIndex { (index, element) in
                    result.append("\n  ")
                    result.append(element.description)
                    if (index != self.count - 1) {
                        result.append(",")
                    }
                }
            }
            
            return "[\(result)\n]"
        }
    }
    
    
    /// Returns a string of the strings joined to the format [x, y, z]
    var descriptionsJoined : String {
        get {
            var result : String = "["
            if self.count > 0 {
                self.forEachIndex { (index, element) in
                    result.append(element.description)
                    if (index != self.count - 1) {
                        result.append(", ")
                    }
                }
            }
            
            return result + "]"
        }
    }
}

public extension Dictionary where Value : CustomStringConvertible {
    
    var descriptionLines : String {
        get {
            var result : [String] = []
            if self.count > 0 {
                self.forEachIndex { (index, element) in
                    result.append("\(element.key) = \(element.value)")
                }
            }
            result.sort()
            return "[\(result.joined(separator: "\n"))\n]"
        }
    }
}

