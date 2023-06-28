//
//  MNPersonStatus.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation

/// Lifecycle status for a user in a website / social network / data collection
public struct MNPersonStatus : Codable, JSONSerializable, Equatable {
    
    public enum MNPStatusType : CaseIterable, Int, Equatable, Codable, Hashable {
        case unknown
        case creating
        case active
        case frozen
        case pending
        case blacklisted
        case deleted
    }
    
    private var _value : MNPStatusType = .creating
    public var value : MNPStatusType {
        get {
            return self._value
        }
        set {
            if newValue != _value {
                _value = newValue
                self.prev = oldValue
                lastChangeDate = Date.now
            }
        }
    }
    public var statusExpirationDate : Date? = nil
    
    var prev : MNPStatusType = .unknown
    var lastChangeDate : Date
    
    init (status:MNPStatusType, expirationDate exDate:Date? = nil) {
        value = status
        prev = .creating
        expirationDate = exDate
        lastChangeDate = Date.now
    }
    
    init () {
        lastChangeDate = Date.now
    }
    
    func setStatus(_ stat : MNPStatusType) {
        self.value = stat // checks for identity
    }
    
    // Static vars:
    public static var creating : MNPersonStatus {
        return MNPersonStatus(status: .creating)
    }
    
    public static var active : MNPersonStatus {
        return MNPersonStatus(status: .active)
    }
    
    public static func frozen(untilDate:Date?) -> MNPersonStatus {
        return MNPersonStatus(status: .frozen, expirationDate:until)
    }
    
    public static func pending(untilDate:Date?) -> MNPersonStatus {
        return MNPersonStatus(status: .pending, expirationDate:untilDate)
    }
    
    public static var blacklisted(untilDate:Date?) -> MNPersonStatus {
        return MNPersonStatus(status: .blacklisted, expirationDate:untilDate)
    }
    
    public static var deleted : MNPersonStatus {
        return MNPersonStatus(status: .deleted)
    }
 }
