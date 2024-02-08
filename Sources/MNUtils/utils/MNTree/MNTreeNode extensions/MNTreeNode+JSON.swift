//
//  MNTreeNode+JSON.swift
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

fileprivate let dlog : Logger? = Logger(label: "MNTreeNode+JSON") // ?.setting(verbose: false, testing: IS_TESTING)

extension MNTreeNode where ValueType : JSONSerializable, IDType : JSONSerializable {
    
}
