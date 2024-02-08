//
//  IntEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

extension Int {
    
    
    /// Convenience / syntactic sugar to add prefix digits to the int for a minimum of charachters:
    /// - Parameter minDigits: minimum amount of digits expected in the resulting string
    /// - Returns: a string describing the int, where prefixing digits pad / fill the string for the minimum charachter length of minDigits
    func asString(minDigits:Int)->String {
        return String(format: "%0\(minDigits)d", self)
    }
    
    /// Convenience / syntactic sugar to add prefix digits to the int for a minimum of charachters:
    /// - Parameter minDigits: minimum amount of digits expected in the resulting string
    /// - Returns: a string describing the int, where prefixing digits pad / fill the string for the minimum charachter length of minDigits
    func toString(minDigits:Int)->String {
        return self.asString(minDigits: minDigits)
    }
}
