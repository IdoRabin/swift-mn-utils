//
//  MNSanitize.swift
//  
//
//  Created by Ido on 27/06/2023.
//

import Foundation

protocol MNSanitizer {
    func sanitize<T>(_ input : T, options:any OptionSet, clipLimit:Int?) -> MNResult<T>?
}
/*
public class MNSanitize {
    static var string = MNSanitizeString()
}

public class MNSanitizeString : MNSanitizer {
    
    struct Options: OptionSet {
        let rawValue: Int
        
        // Remove all emojis
        static let emojis = MNStringSanitizeLevel(rawValue: 1 << 0)
        
        // Remove all digits
        static let digits = MNStringSanitizeLevel(rawValue: 1 << 1)
        
        // Remove all symbols
        static let symbols = MNStringSanitizeLevel(rawValue: 1 << 2)
        
        static let onlyTextOnChar0 = MNStringSanitizeLevel(rawValue: 1 << 3)
        
        static let newlines = MNStringSanitizeLevel(rawValue: 1 << 4)
        
        // Replaces all whitespace chars with the ascci space charachter
        static let spacesOnly = MNStringSanitizeLevel(rawValue: 1 << 5)
        
        static let punctuation = MNStringSanitizeLevel(rawValue: 1 << 6)
        
        
        // Combinations:
        static let all: MNStringSanitizeLevel = [.emojis, .digits, .symbols, .onlyTextOnChar0, .newlines, .spacesOnly, .punctuation]
        
        static let MN_NAME_SANITIZATION = [.onlyTextOnChar0, .newlines, .spacesOnly]
    }
    
    func sanitize<T:String>(_ input : T, options:Options) -> MNResult<T> {
        
        var result = input.trimmingCharacters(in: .whitespaceAndNewline).components(separatedBy: CharacterSet.illegalCharacters).joined(by: "")
        result = result.components(separatedBy: CharacterSet.newlines).remove(elementsEqualTo: "").joined(separator: "")
        
        for option in options.elements {
            switch option {
            case .emojis:           result = result.removingEmojis
            case .digits:           result = result.components(separatedBy: .decimalDigits).joined(by: "")
            case .symbols:          result = result.components(separatedBy: .symbols).joined(by: "")
            case .onlyTextOnChar0:  result = result.trimmingPrefixCharacters(in: CharacterSet.decimalDigits.inverted)
            case .newlines:         result = result.components(separatedBy: .newline).joined(by: "")
            case .spacesOnly:       result = result.components(separatedBy: .whitespace).remove(elementsEqualTo: "").joined(by: " ") // ascii space
            case .punctuation:      result = result.components(separatedBy: .punctuation).joined(by: "")
            }
        }
        
        // TODO: Check if needs RTL Symbols / controlCharacterSet?
        return result
    }
}

*/
