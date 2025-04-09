//
//  MNTreeNode+Identifiable.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

#if TESTING
fileprivate let IS_TESTING = true
#else
fileprivate let IS_TESTING = false || MNUtils.debug.IS_TESTING
#endif

fileprivate let dlog : Logger? = Logger(label: "MNTreeNode+Id-able") // ?.setting(verbose: false, testing: IS_TESTING)


extension MNTreeNode : Identifiable where ValueType : Identifiable, IDType == ValueType.ID {
    public typealias ID = ValueType.ID

    /// The stable identity of the entity associated with this instance. (note! assumes value != nil otherwise, will crash!)
    public var id: ValueType.ID {
        return self.value!.id
    }
    
    /// The safe identity of the entity associated with this instance.
    var safeId: ValueType.ID? {
        return self.value?.id
    }
}

