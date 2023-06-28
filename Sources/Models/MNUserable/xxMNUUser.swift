//
//  MNUser.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation

// Overwridable
// See in MNVaporUtils: MNUser
/*
open class MNUUser : MNUserable, Hashable, Codable, Equatable, JSONSerializable, MNUIDable  {
    // : Identifiable // Model
    // MARK: Static
    public static let schema = "mn_users"
    
    public static var MIN_USERNAME_LEN : UInt = 4
    
    public static var usernameAllowedCharSet: CharacterSet {
        return CharacterSet.usernameAllowedSet
    }
    
    public static var userDomainAllowedCharSet: CharacterSet {
        return .userDomainAllowedSet
    }
    
    // MARK: Status
    public enum Status : Int, Codable {
        case creating
        case rejected
        case approved
        case frozen
        case deleted
    }
    
    // MARK: properties
    open var id: UUID?
    open var username: String?
    open var useremail: String?
    open var avatar: URL?
    open var status: Status = .creating
    
    // MARK: Computed properties
    public var isEmpty : Bool {
        return self.id == nil && (self.username == nil || self.useremail == nil)
    }
    
    
    
    // MARK: Coding keys
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case username = "username"
        case useremail = "useremail"
        case avatar = "avatar"
        case status = "status"
    }
    
    // MARK: lifecycle
    
    // We must have an empty init for Fluent.Model
    required public init() {
        
    }
    
    public init(id: UUID? = nil, name: String, avatar:URL? = nil) {
        self.id = id
        self.username = name
    }
    
    public init(id: UUID? = nil, email: String, avatar:URL? = nil) {
        self.id = id
        self.useremail = email
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNUUser, rhs:MNUUser)->Bool {
        return lhs.id == rhs.id &&
        // TODO: Consider if equality should use id only?
        lhs.username == rhs.username &&
        lhs.useremail == rhs.useremail &&
        lhs.avatar == rhs.avatar &&
        lhs.status == rhs.status
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.username)
        hasher.combine(self.useremail)
        hasher.combine(self.avatar)
        hasher.combine(self.status)
    }
}
*/
