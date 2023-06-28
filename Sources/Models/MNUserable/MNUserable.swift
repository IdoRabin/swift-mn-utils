//
//  MNUserable.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation

public enum MNUserStatus : Int, Codable {
    case creating
    case rejected
    case approved
    case frozen
    case deleted
}
/*
public protocol MNUserable: AnyObject, Equatable, Hashable, MNUIDable {
    
    // MARK: Base properties
    var id: UUID? { get }
    var domain: String? { get }
    var username: String? { get }
    var useremail: String? { get }
    var avatar: URL? { get }
    var status: MNUserStatus { get }
    var info: (any Codable)? { get }

    // Computed properties
    var isEmpty : Bool { get }
}

public extension MNUserable  {
    
    // MARK: Equatable
    static func isEquals(lhs:any MNUserable, rhs:any MNUserable)->Bool {
        return lhs.id == rhs.id &&
            // TODO: Consider if equality should use id only?
            lhs.domain == rhs.domain &&
            lhs.username == rhs.username &&
            lhs.useremail == rhs.useremail &&
            lhs.avatar == rhs.avatar &&
            lhs.status == rhs.status
    }
    
    static func ==(lhs:any MNUserable, rhs:any MNUserable)->Bool {
        return self.isEquals(lhs: lhs, rhs:rhs)
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(domain)
        hasher.combine(username)
        hasher.combine(useremail)
        hasher.combine(avatar)
    }
    
    // MARK: MNUIDable
    var mnUID: MNUID? {
        guard let id = id else {
            return nil
        }
        return MNUID(uid: id, typeStr: "USR")
    }
}
*/
