//
//  MNPersonInfo.swift
//  
//
//  Created by Ido on 19/06/2023.
//

import Foundation
import MNUtils

open class MNPersonInfo : Codable, Hashable, Equatable, JSONSerializable, MNUIDable {
    
    var userId : UUID?
    var lastFetchedDate : Date?
    var name = MNPersonName.empty
    
    public enum CodingKeys : String, CodingKey {
        case userId = "id"
        case lastFetchedDate = "last_fetched_date"
        case name = "name"
        case emails = "emails"
    }
    
    // MARK: MNUIDable
    public var mnUID: MNUID? {
        return MNUID(uid: self.id!, typeStr: "USRINF")
    }
    
    // MARK: Identifiable
    public var id : UUID? {
        return userId ?? UUID.empty
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNUserInfo, rhs:MNUserInfo)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(lastFetchedDate)
        hasher.combine(name)
    }
    
    // MARK: lifecycle
    init(userId: UUID, lastFetchedDate: Date? = nil) {
        self.userId = userId
        self.lastFetchedDate = lastFetchedDate
         self.name = name
    }
    
    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userId, forKey: CodingKeys.userId)
        try container.encodeIfPresent(lastFetchedDate, forKey: CodingKeys.lastFetchedDate)
        try container.encodeIfPresent(name, forKey: CodingKeys.name)
    }
    
    required public init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        userId = try keyed.decode(UUID.self, forKey: CodingKeys.userId)
        lastFetchedDate = try keyed.decodeIfPresent(Date.self, forKey: CodingKeys.lastFetchedDate)
        name = try keyed.decodeIfPresent(MNPersonName.self, forKey: CodingKeys.name)
    }
}
