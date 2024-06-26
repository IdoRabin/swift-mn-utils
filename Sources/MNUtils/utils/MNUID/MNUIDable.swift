//
//  MNUIDable.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

// DO NOT: Identifiable because it clashes with Fluent's Model protocol @ID, which required id to be non-optional (some)
public protocol MNUIDable /* DO NOT: Identifiable */  {
    
    static var mnuidTypeStr : String { get }
    var id : UUID? { get }
    var mnUID : MNUID? { get }
    
    func validateMNUID(_ mnUID:MNUID?) -> Bool
}

public extension MNUIDable {
    func validateMNUID(_ mnUID:MNUID?) -> Bool {
        return (mnUID?.type == Self.mnuidTypeStr)
    }
}

public extension MNUIDable where Self : Identifiable {
    var mnUID : MNUID? {
        guard let id = self.id else {
            return nil
        }
        
        return MNUID(uid: id, typeStr: Self.mnuidTypeStr)
    }
}
