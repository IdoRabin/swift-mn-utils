//
//  MNPersonNameComponents.swift
//  
//
//  Created by Ido on 26/06/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNPersonNameComponents")?.setting(verbose: true)

/// Person name components, based on PersonNameComponents, with an extra thing or two:
public enum MNPersonNameComponents : Int, Codable {
    
    /* Pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr. */
    case namePrefix = 0

    /* Name bestowed upon an individual by one's parents, e.g. Johnathan */
    case givenName

    /* Secondary given name chosen to differentiate those with the same first name, e.g. Maple  */
    case middleName

    /* Name passed from one generation to another to indicate lineage, e.g. Appleseed  */
    case familyName

    /* Post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D. */
    case nameSuffix

    /* Name substituted for the purposes of familiarity, e.g. "Johnny"*/
    case nickname
    
    /* Middle name's initial letter (derivative of middleName) */
    case middleNameInitial
    
    static var all = [.namePrefix, .givenName, .nickname, .middleName, .middleNameInitial, .familyName, .nameSuffix]
    
    var asFoundationPersonNameComponent : [PersonNameComponents] {
        switch self {
        case .namePrefix:   return .namePrefix
        case .givenName:    return .givenName
        case .middleName, .middleNameInitial /* err on more data */:
                            return .middleName
        case .familyName:   return .familyName
        case .nameSuffix:   return .nameSuffix
        case .nickname:     return .nickname
        }
    }
}

public extension PersonNameComponents {
    static var all = [.namePrefix, .givenName, .nickname, .middleName, .familyName, .nameSuffix] // no middleNameInitial
    
    var asMNPersonNameComponent : [MNPersonNameComponents] {
        switch self {
        case .namePrefix:   return .namePrefix
        case .givenName:    return .givenName
        case .middleName:   return .middleName
        case .familyName:   return .familyName
        case .nameSuffix:   return .nameSuffix
        case .nickname:     return .nickname
        }
    }
}

public extension Sequence where Element : MNPersonNameComponents {
    var asFoundationPersonNameComponents : [PersonNameComponents] {
        return self.compactMap { comp in
            return comp.asFoundationPersonNameComponent
        }
    }
}

public extension Sequence where Element : PersonNameComponents {
    var asMNPersonNameComponents : [MNPersonNameComponents] {
        return self.compactMap { comp in
            return comp.asMNPersonNameComponent
        }
    }
}
