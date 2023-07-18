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
    let nameEn : String
    let nameNative : String
    let iso639_1 : String
    let countriesIso3166 : [String]
    let displayFlags : [String/* iso639_1 */:String /* Iso3166 */] // Use "*" as the Key for unknown / unspecified coutry. i.e US flag for "English", even when the actual country we are referring to is unspecified
    
    public var description : String {
        var parts : [String] = []
        if nameEn.count > 0 {
            parts.append(nameEn)
        } else if nameNative.count > 0 {
            parts.append(nameNative)
        } else {
            dlog?.note("MNLanguage has no nameEn and no nameNative")
        }
        
        if countriesIso3166.count > 0 {
            parts.append(countriesIso3166.descriptionsJoined)
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
}
