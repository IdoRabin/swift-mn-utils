//
//  MNUID protocols.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

// We do not name this protocol "MNUIDable" because that protocol will refer to any object that has a MNUIDProtocol complient mnUID member, that identifies it and may be alos used in conjuction to Identifiable.
// See: MNUIDable.swift
public protocol MNUIDProtocol : Hashable, Equatable, Comparable {
    var uid : UUIDv5 { get }
    var type : String { get }
}

public extension MNUIDProtocol /* Default implementations */ {
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(uid)
    }
    
    // MARK: Equatable
    static func ==(lhs:any MNUIDProtocol, rhs:any MNUIDProtocol)->Bool {
        return lhs.type == rhs.type && lhs.uid == rhs.uid
    }
    
    // MARK: Sorted
    static func <(lhs:any MNUIDProtocol, rhs:any MNUIDProtocol)->Bool {
        guard lhs.type == rhs.type else {
            return lhs.type < rhs.type
        }
        return lhs.uid.uuidString < rhs.uid.uuidString
    }
    
    func compare(_ lhs: Self, _ rhs: Self) ->  ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        } else if lhs < rhs {
            return .orderedAscending
        } else { // if lhs > rhs
            return .orderedDescending
        }
        
    }
}

public extension MNUIDProtocol {
    
}
