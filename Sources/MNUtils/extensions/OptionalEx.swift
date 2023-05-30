//
//  OptionalEx.swift
//  XPlan
//
//  Created by Ido on 16/11/2023.
//

import Foundation

fileprivate func formattedValue(_ any: Any) -> String {
    
    switch any {
    case let any as CustomStringConvertible:
        return any.description
    case let any as CustomDebugStringConvertible:
        return any.debugDescription
    default:
        return "\(any)"
    }
}

// Extends optoinals:
func descOrNil(_ any : Any?)->String {
    guard let any = any else {
        return "<nil>"
    }
    
    return formattedValue(any)
}

public extension Optional where Wrapped == String {
    
    /// Returns true when the optional string is nil or empty (has no charachters, count == 0)
    /// NOTE: is also implemented as isNilOrEmpty (same implementation)
    var isEmptyOrNil: Bool {
        return self.isNilOrEmpty
    }
    
    /// Returns true when the optional string is nil or empty (has no charachters, count == 0)
    /// NOTE: is also implemented as isEmptyOrNil (same implementation)
    var isNilOrEmpty: Bool {
        if let value = self {
            return value.count == 0
        }
        return true
    }
    
    var descOrNil: String {
        if let value = self {
            return value
        }
        return "<nil>"
    }
}

public extension Optional /*: CustomDebugStringConvertible */ {
    
    var debugDescription : String {
        return descOrNil
    }
    
    var descOrNil: String {
        
        if let value = self {
            
            return formattedValue(value)
        }
        return "<nil>"
    }
}
