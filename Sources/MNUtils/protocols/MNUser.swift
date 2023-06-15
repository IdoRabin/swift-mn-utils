//
//  MNUserable.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation

// Overwridable
open class MNUser : Hashable, Codable, Equatable, JSONSerializable, MNUIDable  {

    // : Identifiable // Model
    public static let schema = "users"

    // MARK: properties
    public var id: UUID?
    private(set) public var username: String?
    private(set) public var useremail: String?
    private(set) public var avatar: URL?
    
    // MARK: MNUIDable
    public var mnUID: MNUID? {
        guard let id = id else {
            return nil
        }
        return MNUID(uid: id, typeStr: "USR")
    }
    
    // MARK: Coding keys
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case username = "username"
        case useremail = "useremail"
        case avatar = "avatar"
    }
    
    // MARK: lifecycle
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
    public static func ==(lhs:MNUser, rhs:MNUser)->Bool {
        return lhs.id == rhs.id &&
                    lhs.username == rhs.username &&
                    lhs.useremail == rhs.useremail &&
                    lhs.avatar == rhs.avatar
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.username)
        hasher.combine(self.useremail)
        hasher.combine(self.avatar)
    }
}
