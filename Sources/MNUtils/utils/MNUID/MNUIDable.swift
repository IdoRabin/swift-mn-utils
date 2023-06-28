//
//  MNUIDable.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation

// DO NOT: Identifiable because it clashes with Fluent's Model protocol @ID, which required id to be non-optional (some)
public protocol MNUIDable /* DO NOT: Identifiable */  {
    
    var id : UUID? { get }
    var mnUID : MNUID? { get }
}
