//
//  MNPersonStatus.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation

public struct MNPersonStatus {
    public enum MNPStatusType {
        case unknown
        case creating
        case active
        case frozen
        case blacklisted
        case deleted
    }
    
    var value : MNPStatusType = .creating {
        didSet {
            self.prev = oldValue
            lastChangeDate = Date.now
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
}
