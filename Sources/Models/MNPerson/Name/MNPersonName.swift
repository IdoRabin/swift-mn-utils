//
//  MNPersonName.swift
//  
//
//  Created by Ido on 26/06/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNPersonName")?.setting(verbose: true)

/*
    Foundation - PersonNameComponents
    .namePrefix
    .givenName
    .middleName
    .familyName
 
    // -- Post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D.
    .nameSuffix
    
    // -- Name substituted for the purposes of familiarity, e.g. "Johnny"
    .nickname
 */

public struct MNPersonName : JSONSerializable, Hashable, Equatable {
    
    static var PERSON_NAME_MINMAX_LEN_RANGE : Range<UInt> {
        return 5..<256
    }
    
    public enum NameDisplaySize : Int, Codable {
        case initials
        case short
        case medium
        case full
    }
    
    public enum NameType : Int, Codable {
        case european = 0
        case asian
        case arabic
    }
    
    public var type : NameType? = nil
    public var displaySize : NameDisplaySize? = nil
    private (set) public var components : [MNPersonNameComponents:String] = [:]
    // TODO: private (set) public var soundexes : [MNPersonNameComponents:String] = [:] // phonetics?
    
    public var displayName : String {
        return self.asString([.first, .last])
    }
    
    public static var empty : MNPersonName {
        return MNPersonName()
    }
    
    public func component(_ comp: MNPersonNameComponents)->String? {
        guard let str = components[comp], str.count > 0 {
            return nil
        }
        return str
    }
    
    public func has(_ comp: MNPersonNameComponents)->Bool {
        return components.hasKey(comp)
    }
    
    public func asString(asize:NameDisplaySize = .short, atype:NameType = .european, isNonBreaking:Bool = false)->String {
        var comps : [MNPersonNameComponents] = []
        switch (asize, atype) {
        // == .full:
        case (.full, .arabic): fallthrough
        case (.full, .european):
            comps = [.namePrefix, .givenName, .nickname, .middleName, .familyName, .nameSuffix]
        case (.full, .asian):
            comps = [.namePrefix, .familyName, .nickname, .middleName, .givenName, .nameSuffix]
        
        // == .medium:
        case (.medium, .arabic): fallthrough
        case (.medium, .european):
            comps = [.givenName, .nickname, .middleName, .familyName]
        case (.medium, .asian):
            comps = [.familyName, .nickname, .middleName, .givenName]
            
        // == .short, initials *:
        case (.short, .arabic), (.initials, .arabic): fallthrough
        case (.short, .european), (.initials, .european):
            comps = [.givenName, .middleNameInitial, .familyName]
        case (.short, .asian), (.initials, .asian):
            comps = [.familyName, .middleNameInitial, .givenName]
            
        default:
            dlog?.verbose(log: .note, "asString(size:\(asize), type:\(atype)) with unknown case.")
            comps = [.givenName, .nickname, .middleName, .familyName]
        }
        
        var result = self.asString(components: comps, isNonBreaking: isNonBreaking)
        if asize == .initials {
            return result.split(separator: .whitespaceAndNewline).compactMap { str in
                return str.trimmingCharacters(in: .whitespaceAndNewline).substring(to: 1)?.uppercased
            }
        }
        
        return result
    }
    
    public func asString(components comps:[MNPersonNameComponents], isNonBreaking:Bool = false)->String {
        // NOTE: keep order of comps!
        var comps = comps.intersection(with: self.components.sortedKeys/* by enum int value */)
        var strs : [String] = []
        for comp in comps {
            if comp == .middleNameInitial {
                strs.appendIfNotNil(components[.middleName]?.substring(to: 1))
            } else {
                strs.appendIfNotNil(components[comp])
            }
        }
        
        // Whitespace method
        return strs.joined(separator: isNonBreaking ? String.NBSP : " ")
    }
    
    public var isEmpty : Bool {
        return components.count == 0
    }
    
    public static func isValidNameComponent(component: MNPersonNameComponents, value:String)->Bool {
        switch component {
            
        }
    }
    
    public static func isValidNameComponents(_ comps: [MNPersonNameComponents:String], sanitize:Bool = false)->Bool {
        var result = true
        for (comp, val) in comps {
            result = result & isValidNameComponent(component: comp, value: val)
        }
        return result
    }
    
    
    // TODO: Create from one string
    public static func fromString(_ str : String, type:NameType = .european)->MNPersonName {
        
    }
    
    init(_ str:String, type:NameType = .european) {
        
    }
}
