//
//  FloatEx.swift
//  Bricks
//
//  Created by Ido on 06/01/2022.
//

import Foundation

extension Float {
    
    /// Round to the nth decimal digit
    /// The Float 100.45234 for the parameter dec == 2 should return a Float 100.45
    /// - Parameter num_places: number of decimal placees to keep
    /// - Returns: a Dloat numbre rounded to the dec's place
    func rounded(dec num_places:Int)->Float {
        let prec = Float(pow(10.0, Float(max(num_places, 0))))
        return (self * prec).rounded() / prec
    }
    
    func stringValue(dec num_places:Int = 2)->String {
        return String(format: "%0.\(num_places)f", self)
    }
    
    func toString(dec num_places:Int = 2)->String {
        return self.stringValue(dec: num_places)
    }
}

extension Double {
    
    /// Round to the nth decimal digit
    /// The Double 100.45234 for the parameter dec == 2 should return a Double 100.45
    /// - Parameter num_places: number of decimal placees to keep
    /// - Returns: a Double numbre rounded to the dec's place
    func rounded(dec num_places:Int)->Double {
        let prec = Double(pow(10.0, Double(max(num_places, 0))))
        return (self * prec).rounded() / prec
    }
    
    func stringValue(dec num_places:Int = 2)->String {
        return String(format: "%0.\(num_places)f", self)
    }
    
    func toString(dec num_places:Int = 2)->String {
        return self.stringValue(dec: num_places)
    }
}

extension CGFloat {
    /// Round to the nth decimal digit
    /// The Double 100.45234 for the parameter dec == 2 should return a Double 100.45
    /// - Parameter num_places: number of decimal placees to keep
    /// - Returns: a Double numbre rounded to the dec's place
    func rounded(dec num_places:Int)->Double {
        return Double(self).rounded(dec: num_places)
    }
    
    func stringValue(dec num_places:Int = 2)->String {
        return Double(self).stringValue(dec: num_places)
    }
    
    func toString(dec num_places:Int = 2)->String {
        return self.stringValue(dec: num_places)
    }
}
