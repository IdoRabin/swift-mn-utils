//
//  File.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation
import DSLogger

open class MNAccessTokenConsts {
    // MARK: Consts
    public static let SEPARATOR = "|"
    static let DEFAULT_TOKEN_EXPIRATION_DURATION : TimeInterval = TimeInterval.SECONDS_IN_A_MONTH * 1 // 1 month
    static let ACCESS_TOKEN_UUID_STRING_LENGTH = 36
    static let ACCESS_TOKEN_SUFFIX = "_tk"
    static let ACCESS_TOKEN_EXPIRATION_DURATION : TimeInterval = 2 * TimeInterval.SECONDS_IN_A_WEEK
    static let ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD : TimeInterval = 20 * TimeInterval.SECONDS_IN_A_MINUTE
    
    // MARK: Static
    // public static let emptyToken : MNAccessToken = MNAccessToken(uuid:UUID(uuidString: UID_EMPTY_STRING)!)
    // public static let zerosToken = emptyToken
}

/*
fileprivate let dlog : DSLogger? = DLog.forClass("MNAccessToken")
public protocol MNAccessTokenable : Equatable, Hashable, Codable {
    var id: UUID? { get } // NOTE: this is the ID of the AccessToken, not the id of the user
    var expirationDate : Date  { get }
    var lastUsedDate : Date  { get }
    var userUIDString : String?  { get }
    init(accessTokenable atoken:any MNAccessTokenable)
}

public extension MNAccessTokenable /* Default implementation */ {
    // MARK: Equatable
    static func ==(lhs:any MNAccessTokenable, rhs:any MNAccessTokenable)->Bool {
        self.isEquals(lhs: lhs, rhs: rhs)
    }
    
    fileprivate static func isEquals(lhs:any MNAccessTokenable, rhs:any MNAccessTokenable)->Bool {
        //  We ignore the expiration date
//        if let luserId = lhs.user?.id, let ruserId = rhs.user?.id {
//            return luserId == ruserId
//        } else
        if let luserId = lhs.userUIDString, let ruserId = rhs.userUIDString {
            return luserId == ruserId
        } else {
            return !(lhs.id?.isEmpty == false) && lhs.id == rhs.id
        }
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
}

open class MNAccessToken : MNAccessTokenable, JSONSerializable {
    typealias Consts = MNAccessTokenConsts
    
    // MARK: Coding keys
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case expirationDate = "expiration_date"
        case lastUsedDate = "last_used_date"
        case user = "user_id"
        case userUUIDStr = "user_id_str"
    }
    
    // MARK: Properties / members
    open var id: UUID? // NOTE: this is the ID of the AccessToken, not the id of the user
    open var expirationDate : Date
    private (set) open var lastUsedDate : Date
    open weak var user: (any MNUserable)?
    private (set) open var userUIDString : String?
    
    // MARK: Lifecycle
    // Initializer requirement 'init()' can only be satisfied by a 'required' initializer in non-final class 'AccessToken'
    required public init() {
        id = UUID()
        expirationDate = Date(timeIntervalSinceNow: MNAccessToken.Consts.DEFAULT_TOKEN_EXPIRATION_DURATION)
        self.lastUsedDate = Date()
    }
    
    required public init(uuid:UUID) {
        id = uuid
        expirationDate = Date(timeIntervalSinceNow: MNAccessToken.Consts.DEFAULT_TOKEN_EXPIRATION_DURATION)
        self.lastUsedDate = Date()
    }
    
    public required init(accessTokenable atoken:any MNAccessTokenable) {
        self.id = atoken.id
        self.expirationDate = atoken.expirationDate
        self.lastUsedDate = atoken.lastUsedDate
        self.user = nil // TODO: // self.user = atoken.use .. load? 
        self.userUIDString = atoken.userUIDString
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNAccessToken, rhs:MNAccessToken)->Bool {
        return isEquals(lhs: lhs, rhs: rhs)
    }
    
    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(lastUsedDate, forKey: CodingKeys.lastUsedDate)
        try container.encode(expirationDate, forKey: CodingKeys.expirationDate)
        try container.encodeIfPresent(user?.id, forKey: CodingKeys.user)
        try container.encodeIfPresent(user?.id?.uuidString, forKey: CodingKeys.userUUIDStr)
    }
    
    required public init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try keyed.decodeIfPresent(UUID.self, forKey: CodingKeys.id)
        self.expirationDate = try keyed.decode(Date.self, forKey: CodingKeys.expirationDate)
        self.lastUsedDate = try keyed.decode(Date.self, forKey: CodingKeys.lastUsedDate)
        self.userUIDString = try keyed.decodeIfPresent(String.self, forKey: CodingKeys.userUUIDStr) ?? ""
    }
    
    // MARK: Public
    public func setWasUsedNow() {
        lastUsedDate = Date()
    }
    
    public var isWasUsedRecently : Bool {
        return abs(self.lastUsedDate.timeIntervalSinceNow) < Self.Consts.ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD
    }
    
    /// Returns true when token has a valid uuid (not nil or corrupt) and the token has not expired yet.
    public var isValid : Bool {
        guard id != nil else {
            dlog?.warning("AccessToken.isValid is false becuase the id (uuid) is the zero uuid \(UID_EMPTY_STRING)!")
            return false
        }
        return !self.isExpired
    }
    
    /// Returns true when token is expired. (expiration date has passed)
    public var isExpired : Bool {
        guard !self.expirationDate.isInThePast else {
            dlog?.warning("AccessToken.isExpired is true becuase the token expiration date has passed \(self.expirationDate.description)!")
            return true
        }
        return false
    }
    
    /// Returns true when the internal property "id" is nil or equals "empty" UUID (00000000-0000-0000-0000-000000000000)
    public var isEmpty : Bool {
        guard let id = self.id else {
            dlog?.warning("AccessToken.isEmpty is true becuase the id (uuid) is nil!")
            return true
        }
        
        guard id.uuidString == UID_EMPTY_STRING else {
            dlog?.warning("AccessToken.isEmpty is true becuase the id (uuid) is UID_EMPTY_STRING!")
            return true
        }
        
        return false
    }
    
}
*/
