//
//  MNUIDable.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation

// DO NOT: Identifiable because it clashes with Fluent's Model protocol @ID
public protocol MNUIDable {
    
    var id : UUID? { get }
    var mnUID : MNUID? { get }
}
