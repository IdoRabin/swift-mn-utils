//
//  MNPersonStatus.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation


/// Lifecycle status for a user in a website / social network / data collection
public struct MNPersonStatus {
    
    public enum MNPStatusType : Int {
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
    
    var prev : MNPStatusType = .unknown
    var lastChangeDate : Date
    
    init (status:MNPersonStatusType) {
        value = status
        prev = .creating
        lastChangeDate = Date.now
    }
    
    init () {
        lastChangeDate = Date.now
    }
    
    func setStatus(_ stat : MNPersonStatus) {
        self.value = stat
    }
 }
