//
//  MNUserable.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation

public class MNUser : Hashable, Codable, Equatable  {
    
    // : Identifiable // Model
    public static let schema = "users"

    // MARK: properties
    public var id: UUID?
    private(set) public var username: String?
    private(set) public var email: String?
    private(set) public var avatar: URL?
    private(set) public var createdAt: Date?
    private(set) public var deletedAt: Date?

    // MARK: Coding keys
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case username = "username"
        case email = "email"
        case avatar = "avatar"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
    
    // MARK: lifecycle
    required public init() {
        self.createdAt = Date.now
    }

    public init(id: UUID? = nil, name: String, avatar:URL? = nil) {
        self.id = id
        self.username = name
        self.createdAt = Date.now
    }
    
    public init(id: UUID? = nil, email: String, avatar:URL? = nil) {
        self.id = id
        self.email = email
        self.createdAt = Date.now
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNUser, rhs:MNUser)->Bool {
        return lhs.id == rhs.id &&
                    lhs.username == rhs.username &&
                    lhs.email == rhs.email &&
                    lhs.createdAt == rhs.createdAt &&
                    lhs.avatar == rhs.avatar
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.username)
        hasher.combine(self.email)
        hasher.combine(self.avatar)
        hasher.combine(self.createdAt)
        hasher.combine(self.deletedAt)
    }
}

extension MNUser : JSONFileSerializable {
    public static func loadFromJSON<T>(_ fileurl: URL) -> Result<T, Error> where T : JSONFileSerializable {
        // TODO: implement loadFromJSON
        return .failure(MNError(code: .misc_failed_parsing, reason: "MNUser.loadFromJSON for \(T.self) failed!"))
    }
    
    
}
