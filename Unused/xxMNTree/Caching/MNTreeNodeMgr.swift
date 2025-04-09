//
//  MNTreeNodeMgr.swift
//  MNUtils
//
//  Created by ido on 19/10/2024.
//

import Foundation
import Logging

#if TESTING
fileprivate let IS_TESTING = true
#else
fileprivate let IS_TESTING = false || MNUtils.debug.IS_TESTING
#endif

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeMgr") // ?.setting(verbose: false, testing: IS_TESTING)

/// Singleton MNTreeNode manager. Mainy used for containing caches when the nodes IS_CACHED == true, and using "quickmaps"
public class MNTreeNodeMgr {
    // MARK: Types
    // MARK: Const
    // MARK: Static
    
    // MARK: Properties / members
    private var caches : [String:any MNTreeNodeCacheProtocol] = [:]
    
    // MARK: Private
    // MARK: Lifecycle
    // MARK: Singleton
    public static let shared = MNTreeNodeMgr()
    private init(){
        
    }
    
    // MARK: Public
    
    // MARK: Caching
    func cacheFor<ValueType: Hashable, IDType: Hashable>(node:MNTreeNode<ValueType, IDType>) -> MNTreeNodeCache<MNTreeNode<ValueType, IDType>> {
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let key = CacheType.NodeType.TREE_NODE_TYPE_KEY
        var result : CacheType? = caches[key] as? CacheType
        if result == nil {
            result = CacheType()
            caches[key] = result
        }
        
        return result!
    }
    
    func cacheFor<NodeType: MNTreeNodeProtocol>(nodeType:NodeType.Type) -> MNTreeNodeCache<MNTreeNode< NodeType.ValueType, NodeType.IDType>> {
        typealias CacheType = MNTreeNodeCache<MNTreeNode<NodeType.ValueType, NodeType.IDType>>
        let key = CacheType.NodeType.TREE_NODE_TYPE_KEY
        var result : CacheType? = caches[key] as? CacheType
        if result == nil {
            result = CacheType()
            caches[key] = result
        }
        
        return result!
    }
    
    func cacheFor(nodeTypeString key:String) -> Any? {
        return caches[key]
    }
    
    func clear() {
        dlog?.notice("MNTreeNodeMgr.shared.clear() (will clear \(self.caches.count) existing caches)")
        
        caches = [:]
    }
}
