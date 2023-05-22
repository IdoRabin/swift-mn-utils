//
//  NSLock+Blocks.swift
//  Ido Rabin
//
//  Created by Ido Rabin on 15/11/2017.
//  Copyright © 2022 Ido Rabin. All rights reserved.
//

import Foundation

public extension NSLock {
    
    /// Lock the lock and release when the block is performed
    ///
    /// - Parameter block: block to perform while the lock is locked
    func lock(_ block:()->()) {
        self.lock()
        var retainer : NSLock? = self
        block()
        self.unlock()
        if (retainer != nil) {retainer = nil}
    }
}

public extension NSRecursiveLock {
    /// Lock the lock and release when the block is performed
    ///
    /// - Parameter block: block to perform while the lock is locked
    func lock(_ block:()->()) {
        self.lock()
        var retainer : NSRecursiveLock? = self
        block()
        self.unlock()
        if (retainer != nil) {retainer = nil}
    }
}
