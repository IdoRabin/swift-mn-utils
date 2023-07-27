//
//  File.swift
//  
//
//  Created by Ido on 12/07/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNLanguage")

public struct MNLanguage : CustomStringConvertible, Codable, Equatable, Hashable {
    
    /// English name of the language, written in english
    let nameEn : String
    
    /// Native name of the language, written in its alphabet, for example "עברית" for Hebrew.
    let nameNative : String
    
    /// 2 char code of the language using iso639_1 strandard
    let iso639_1 : String
    
    /// Countries where this language is spoken / national language (using Iso3166-α2 standard)
    ///  The first country in the list will describe the default flag for the language if location / country are unknown / unspecified.
    let countriesIso3166_2 : [String]
    
    public var description : String {
        var parts : [String] = []
        if nameEn.count > 0 {
            parts.append(nameEn)
        } else if nameNative.count > 0 {
            parts.append(nameNative)
        } else {
            dlog?.note("MNLanguage has no nameEn and no nameNative")
        }
        
        if countriesIso3166_2.count > 0 {
            parts.append(countriesIso3166_2.descriptionsJoined)
        }
        return parts.joined(separator: ";")
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNLanguage, rhs:MNLanguage)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(iso639_1)
    }
    
    public static var `default` : MNLanguage {
        return MNLanguage(
            nameEn: "English",
            nameNative: "English",
            iso639_1: "en",
            countriesIso3166_2: ["US", "UK", "CA", "AU"])
    }
}
