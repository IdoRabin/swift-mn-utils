//
//  FloatEx.swift
//  Bricks
//
//  Created by Ido on 06/01/2022.
//

import Foundation

public extension Float {
    
    /// Round to the nth decimal digit.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal placees to keep
    /// - Returns: a floating number rounded to the dec's place
    @inlinable func rounded(decimal num_places:Int)->Float {
        let prec = Float(pow(10.0, Float(max(num_places, 0))))
        return (self * prec).rounded() / prec
    }
    
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func stringValue(decimal num_places:Int = 2)->String {
        return String(format: "%0.\(num_places)f", self)
    }
    
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// NOTE: Convenience function - exact same implementation as stringValue(decimal:).
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func toString(decimal num_places:Int = 2)->String {
        return self.stringValue(decimal: num_places)
    }
}

public extension Double {
    
    /// Round to the nth decimal digit.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal placees to keep
    /// - Returns: a floating number rounded to the dec's place
    @inlinable func rounded(decimal num_places:Int)->Double {
        let prec = Double(pow(10.0, Double(max(num_places, 0))))
        return (self * prec).rounded() / prec
    }
    
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func stringValue(decimal num_places:Int = 2)->String {
        return String(format: "%0.\(num_places)f", self)
    }
    
    
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// NOTE: Convenience function - exact same implementation as stringValue(decimal:).
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func toString(decimal num_places:Int = 2)->String {
        return self.stringValue(decimal: num_places)
    }
}

public extension CGFloat {
    
    /// Round to the nth decimal digit.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal placees to keep
    /// - Returns: a floating number rounded to the dec's place
    @inlinable func rounded(decimal num_places:Int)->Double {
        return Double(self).rounded(decimal: num_places)
    }
    
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func stringValue(decimal num_places:Int = 2)->String {
        return Double(self).stringValue(decimal: num_places)
    }
    /// Return a string value of a floating number, with a given decimal digit percision.
    /// NOTE: Convenience function - exact same implementation as stringValue(decimal:).
    /// For example: the value 100.45234 for the parameter decimal == 2 should return a value of 100.45
    /// - Parameter decimal: number of decimal places (precision) to return in the string.
    /// - Returns: String resentation of the float, formatted to the provided decimal place
    @inlinable func toString(decimal num_places:Int = 2)->String {
        return self.stringValue(decimal: num_places)
    }
}
