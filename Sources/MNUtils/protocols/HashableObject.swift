//
//  HashableObject.swift
//  Bricks
//
//  Created by Ido Rabin for Bricks on 17/1/2024.Copyright © 2024 Bricks. All rights reserved.
//

import Foundation

/// Alias for an object that is both an (retainable) object and Hashable
/// This will allow creating hashable, comperable weak object wrappers etc.
public protocol HashableObject : Hashable, AnyObject {
    // 
}

public protocol EquatableObject : Hashable, AnyObject {
}
