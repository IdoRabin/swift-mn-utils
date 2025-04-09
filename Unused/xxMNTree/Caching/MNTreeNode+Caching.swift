//
//  MNTreeNode+Caching.swift
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

fileprivate let dlog : Logger? = Logger(label: "MNTreeNode+Cache") // ?.setting(verbose: false, testing: IS_TESTING)

protocol MNTreeNodeCacheProtocol<NodeType> where NodeType : MNTreeNode<ValueType, IDType> {
    associatedtype IDType : Hashable
    associatedtype ValueType : Hashable
    associatedtype NodeType : MNTreeNode<ValueType, IDType>
    
    var isEmpty : Bool { get }
}

extension MNTreeNode /* CACHING */ {
    
    // MARK: Static public
    
    // ON Main thread w/ trampoline
    static func registerToQuickMap(node:SelfType) {
        guard Self.IS_CACHED else {
            return
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) {
                [self, node] in self.registerToQuickMap(node:node)
            }
            return
        }
        
        let cache = MNTreeNodeMgr.shared.cacheFor(node: node)
        cache.register(node: node)
    }
    
    static func unregisterFromQuickMap(byId id: IDType, node:SelfType? = nil, ctx:String) {
        guard Self.IS_CACHED else {
            return
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue && !ctx.hasSuffix("delayedExec") else {
            MNExec.exec(afterDelay: 0) {
                [self, node] in self.unregisterFromQuickMap(byId:id, node:node, ctx: ctx + ">delayedExec")
            }
            return
        }
        
        let cache = MNTreeNodeMgr.shared.cacheFor(nodeType: SelfType.self)
        cache.unregister(byId: id, node: node, ctx: ctx + ".cache")
    }
    
    static func removeFromReconstruction(byId id:IDType) {
        guard Self.IS_CACHED else {
            return
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) {
                [self, id] in self.removeFromReconstruction(byId:id)
            }
            return
        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        cache.removeFromReconstruction(byId: id)
        // dlog?.info("\(self) removeFromReconstruction(byId: \(id)) | \(cache)")
    }
    
    static func addToReconstrutionList(id: IDType, value:ValueType?, parentId:IDType?, depth:DepthToReconstrut) {
        guard Self.IS_CACHED else {
            return
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) {
                self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: depth)
            }
            return
        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        cache.addToReconstruction(id: id, value: value, parentId: parentId, depth: depth)
    }
    
    static func attemptReconstruction(context:String, andRebuildQuickMap:Bool = true) {
        guard Self.IS_CACHED else {
            return
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) {
                self.attemptReconstruction(context: context, andRebuildQuickMap: andRebuildQuickMap)
            }
            return
        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        cache.attemptReconstruction(context:context, andRebuildQuickMap:andRebuildQuickMap)
    }
    
    // On current thread (no trampoline)
    static func quickFetch(byId id: IDType)->SelfType? {
        guard Self.IS_CACHED else {
            return nil
        }
        
//        // Trampoline ??
//        guard DispatchQueue.isMainQueue else {
//            DispatchQueue.main.async {[self, id] in self.quickFetch(byId:id) }
//            return nil
//        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        let result = cache.quickFetch(byId: id)
        dlog?.trace("\(self) quickFetch(byId: \( "\(id)" )) | \(cache) | result: \( (result?.id).descOrNil )")
        return result
    }
    
    static func quickFetchContains(id: IDType)->Bool {
        guard Self.IS_CACHED else {
            return false
        }

        //        // Trampoline ??
        //        guard DispatchQueue.isMainQueue else {
        //            DispatchQueue.main.async {[self, id] in self.quickFetch(byId:id) }
        //            return nil
        //        }
                
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        return cache.quickFetchContains(id: id)
        
    }
    static var rootNodes : [SelfType]? {
        guard Self.IS_CACHED else {
            return nil
        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        
        // Find all root nodes:
        let result = cache._treeRoots.values.uniqueElements().filter { node in
            node.isRoot
        }
        
        let cacheKey = cache.TREE_NODE_TYPE_KEY
        MNExec.debounceExecutingLastBlockOnly(withKey: cacheKey, afterDelay: 0.02) { [weak cache] in
            cache?.invalidate("MNTreeNode.rootNodes.debounce [\(cacheKey.trimmingCharacters(in: .whitespacesAndNewlines))]")
        }
        
        if MNUtils.debug.IS_DEBUG, let dlog = dlog {
            dlog.trace("\(self) rootNodes (\(result.ids.descriptions().descriptionJoined)")
        }
        
        return result
    }
    
    
    /// Will return all root nodes for this specialized MNTreeNode tree (i.e the same IDTtpe and ValueType as of this instance.
    var allRootNodesForSelfOfHomogenousType : [SelfType]? {
        return Self.rootNodes
    }
    
    // MARK: public (convenience)
    func attemptReconstruction(context:String, andRebuildQuickMap:Bool = true) {
        Self.attemptReconstruction(context: context, andRebuildQuickMap: andRebuildQuickMap)
    }
    
    func addToReconstrutionList(id: IDType, value:ValueType?, parentId:IDType?, depth:DepthToReconstrut) {
        Self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: depth)
    }
    
    func removeFromReconstruction(byId id:IDType) {
        Self.removeFromReconstruction(byId: id)
    }
    
    func quickFetchContains(id: IDType) -> Bool {
        Self.quickFetchContains(id: id)
    }
    
    func quickFetch(byId id: IDType)->SelfType? {
        return Self.quickFetch(byId: id)
    }
    
    func registerToQuickMap() {
        Self.registerToQuickMap(node: self)
    }
    
    func unregisterFromQuickMap(ctx:String) {
        Self.unregisterFromQuickMap(byId: self.id, node: self, ctx: ctx + ">MNTreeNode.unregisterFromQuickMap.id[\(self.id)]")
    }
    
    @discardableResult
    func rebuildQuickMap() -> Int? {
        guard Self.IS_CACHED else {
            return nil
        }
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) {
                self.rebuildQuickMap()
            }
            return nil
        }
        
        typealias CacheType = MNTreeNodeCache<MNTreeNode<ValueType, IDType>>
        let cache : CacheType = MNTreeNodeMgr.shared.cacheFor(nodeType: Self.self)
        return cache.rebuildQuickMap(node: self)
    }
    
}
