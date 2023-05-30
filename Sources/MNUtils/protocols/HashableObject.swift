//
//  HashableObject.swift
//  Bricks
//
//  Created by Ido Rabin for Bricks on 30/10/2017.
//  Copyright © 2017 Bricks. All rights reserved.
//

import Foundation

/// Alias for an object that is both an (retainable) object and Hashable
/// This will allow creating hashable, comperable weak object wrappers etc.
public protocol HashableObject : Hashable, AnyObject {
    // 
}

public protocol EquatableObject : Hashable, AnyObject {
}
