//
//  MNTreeNode+MNUIDable.swift
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

fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNode+MNUIDable")?.setting(verbose: false, testing: IS_TESTING)

extension MNTreeNode : MNUIDable where ValueType : MNUIDable, IDType == UUID? {
    
    // MARK: MNUIDable
    public static var mnuidTypeStr : String {
        return ValueType.mnuidTypeStr
    }
    
    // Override ID property:
    public var id: UUID? {
        get {
            return value?.id
        }
        set {
            dlog?.warning("MNTreeNode where node value is MNUIDable id value is read only. (set .value.id directly, if possible)")
        }
    }
    
    // Convenience MNUID property:
    public var mnUID: MNUID? {
        get {
            return value?.mnUID
        }
    }
    
}
