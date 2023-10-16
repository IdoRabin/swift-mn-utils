//
//  MNTreeNode+JSON.swift
//  
//
//  Created by Ido on 10/09/2023.
//

import Foundation
import DSLogger

#if TESTING
fileprivate let IS_TESTING = true
#else
fileprivate let IS_TESTING = false || MNUtils.debug.IS_TESTING
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNode+JSON")?.setting(verbose: false, testing: IS_TESTING)

extension MNTreeNode where ValueType : JSONSerializable, IDType : JSONSerializable {
    
}
