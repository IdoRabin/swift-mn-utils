//
//  CharacterSetEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public extension CharacterSet {
    
    /// All punctuation characters except perdiod (".")
    static let punctuationCharactersWithoutPeriod = CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "."))
    
    /// All charahters for a standard expressible hex number string including "x" (lower and upper cases included)
    static let hexCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdefxX")
    
    /// All charahters in the english / latin alphabet : A-Z and a-z only.
    static let latinAlphabet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    
    /// All charahters in the english / latin decimal digits : 0-9 only
    static let latinDigits = CharacterSet(charactersIn: "01234567890")
    
    /// All charahters in the english / latin decimal digits : 0-9, period, plus and minus signs, comma and thousand seperators for many languages
    static let latinDigitsEx = CharacterSet(charactersIn: "01234567890+-.,٫‎٬⠨‎⎖") // thousand seperators: arabic, arabic, persian, braille, decimal separator key
    
    /// All charahters allowed in a base64 string (excluding the equals sign that sometimes suffixes it)
    static let base64 = latinAlphabet.union(.decimalDigits)
    
    /// All charahters allowed in a base64 string (includeing the equals sign that sometimes suffies it)
    static let base64WithEqualSign = base64.union(CharacterSet(charactersIn: "="))
    
    /// All characters
    static let uuidStringCharacters =  CharacterSet.hexCharacters.union(CharacterSet(charactersIn: "-"))
    
    static let nonAlphanumerics =  CharacterSet.alphanumerics.inverted
    
    // NOTE: for Emoji-cleanup or testing, see String+Emoji.swift, since its not as simple as a character set.
}

public extension CharacterSet /* App-Specific */ {
    
    static let usernameAllowedSet = CharacterSet.latinAlphabet.union(.latinDigits).union(CharacterSet(charactersIn: "-_"))
    
    static let userDomainAllowedSet = CharacterSet.usernameAllowedSet.union(CharacterSet(charactersIn: "."))
    
    static let strictFilenameDisallowedChars = "*\\/:"
    static let strictFilenameAllowedSet = CharacterSet.latinAlphabet.union(.latinDigits)
        .union(.punctuationCharacters)
        .subtracting(CharacterSet(charactersIn: strictFilenameDisallowedChars))
    static let strictFilenameDisallowedSet = strictFilenameAllowedSet.inverted
}
