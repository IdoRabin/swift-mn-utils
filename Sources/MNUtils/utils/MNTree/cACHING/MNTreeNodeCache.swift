//
//  MNTreeNodeCache.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeCache") // ?.setting(verbose: false, testing:MNUtils.debug.IS_TESTING)

class MNTreeNodeCache<NodeType:MNTreeNodeProtocol> : MNTreeNodeCacheProtocol, CustomStringConvertible where NodeType : AnyObject {
    
    // MARK: Types
    typealias IDType = NodeType.IDType
    typealias ValueType = NodeType.ValueType
    typealias NodeType = MNTreeNode<ValueType, IDType>
    typealias MNNodeType = MNTreeNode<ValueType, IDType>
    typealias ReconstructionItem = MNTNReconstructionItem<ValueType, IDType>
    typealias DepthToReconstrut = ReconstructionItem.DepthToReconstrut
    
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    private (set) public var _treeCache = MNCache<NodeType.IDType, NodeType>(name: "MNTreeNode.cache", maxSize: 8196)
    private (set) public var _treeReconstructionWaitingList : [ReconstructionItem] = []
    private (set) public var _treeReconstructionIds = Set<IDType>()
    // private (set) public var _treeRoots = WeakSet<NodeType, WeakHashable<NodeType>>()
    private (set) public var _treeRoots = WeakWithMemAddrSet<NodeType, WeakWithMemAddr<NodeType>>()
    private (set) public var _expectedTotal : Int = 0
    
    // MARK: Private
    // MARK: Lifecycle
    init() {
        _treeCache.name = self.TREE_NODE_TYPE_KEY.camelCaseToSnakeCase() + ".cache"
    }
    
    var TREE_NODE_TYPE_KEY : String {
        return NodeType.TREE_NODE_TYPE_KEY
    }
    
    // MARK: Public
    var isEmpty : Bool {
        return _treeCache.count == 0
    }
    
    var description: String {
        return "<MNTreeNodeCache \(self.TREE_NODE_TYPE_KEY)>"
    }
    
    private func guardResume(ctx:String)->Bool {
        guard MNExec.isMain else {
            dlog?.notice("\(ctx) should only run on the main thread / actor / dispatch queue!")
            return false
        }
        return true
    }
    
    // Convenience
    private func updateRootStatus(node:NodeType) {
        self.updateRootStatuses(nodes: [node])
    }
    
    private func updateRootStatuses(nodes:[NodeType]) {
        guard guardResume(ctx:"updateRootStatus") else { return }
        
        self._treeRoots.add(values: nodes) { node in
            node.isRoot
        }
        self._treeRoots.remove { value in
            !value.isRoot
        }
    }
    
    func register(node:NodeType) {
        guard guardResume(ctx:"register") else { return }
        self.updateRootStatus(node: node)
        
        if !self._treeCache.hasValue(forKey: node.id) {
            dlog?.trace("\(self.TREE_NODE_TYPE_KEY) register | \( "\(node.id)" )")
            self._treeCache[node.id] = node
            if self._treeReconstructionIds.contains(node.id) {
                dlog?.info("\(self.TREE_NODE_TYPE_KEY) register for: = \( "\(node.id)" ) = is a known reconstruction id")
                self.attemptReconstruction(context: "register(node id:\( "\(node.id)" ))", andRebuildQuickMap: MNNodeType.IS_CACHED)
            }
        } else {
            dlog?.notice("\(self.TREE_NODE_TYPE_KEY) register | \( "\(node.id)" ) - was already registered.")
        }
        
        
    }
    
    func unregister(byId id: IDType, node:NodeType?) {
        guard guardResume(ctx:"unregister") else { return }
        
        if self._treeCache.hasValue(forKey: id) {
            let indent = "   ".repeated(times: (node as! MNNodeType).depth)
            dlog?.info("\(indent) \(self.TREE_NODE_TYPE_KEY) unregister | \( "\(id)" )")
            self._treeCache[id] = nil
        } else {
            dlog?.verbose(symbol:.warning,"   ".repeated(times: (node as! MNNodeType).depth) +
                          "\(self.TREE_NODE_TYPE_KEY) unregister | \(id) - was not found!")
        }
        
        if let node = node as? MNNodeType {
            self._treeRoots.remove(value: node as! NodeType)
        } else {
            self._treeRoots.remove(values: self._treeRoots.values) { node in
                node.id == id
            }
        }
    }
    
    func quickFetch(byId id: IDType)->NodeType? {
        let result = self._treeCache[id]
        if dlog?.isVerboseActive == true {
            dlog?.successOrFail(condition: result != nil,
                                succStr: "\(self.TREE_NODE_TYPE_KEY) quickFetch id: \(id) | was found",
                                failStr: "\(self.TREE_NODE_TYPE_KEY) quickFetch id: \(id) | was NOT found.")
        }
        return result
    }
    
    func quickFetchContains(id: IDType)->Bool {
        let result = self._treeCache.hasValue(forKey: id)
        if dlog?.isVerboseActive == true {
            dlog?.successOrFail(condition: result,
                                succStr: "\(self.TREE_NODE_TYPE_KEY) quickFetchContains id: \(id) | was found",
                                failStr: "\(self.TREE_NODE_TYPE_KEY) quickFetchContains id: \(id) | was NOT found.")
        }
        return result
    }
    
    @discardableResult
    func rebuildQuickMap(byId id:IDType) -> Int? {
        guard guardResume(ctx:"rebuildQuickMap") else { return nil }
        guard let node = self.quickFetch(byId: id) else {
            dlog?.notice("rebuildQuickMap(byId:\( "\(id)" ) was not found!")
            return nil
        }
        
        return self.rebuildQuickMap(node: node)
    }
    
    @discardableResult
    func rebuildQuickMap(node:NodeType) -> Int? {
        guard guardResume(ctx:"rebuildQuickMap") else { return nil }
        
        var root : MNNodeType = node as! MNNodeType
        if node.parent != nil {
            root = node.root
            dlog?.info("rebuildQuickMap for \( "\(node.id)" ) (using root: \( "\(root.id)" ))")
        } else {
            dlog?.info("rebuildQuickMap for \( "\(node.id)" )")
        }
        
        var count : Int = 0
        root.recourseChildren({ node, depth in
            var parentMemStr = "                 "
            var parentId = " NIL"
            if let parent = node.parent {
                parentMemStr =  MemoryAddress(of: parent).description
                parentId = "\(parent.id)".paddingLeft(toLength: 3, withPad: " ")
            }
            let nodeId = "\(node.id)".paddingLeft(toLength: 3, withPad: " ")
            
            dlog?.info("   rebuildQuickMap parent:\(parentId) \(parentMemStr) child:\(nodeId) \(MemoryAddress(of: node).description)")
            if let mnNode = node as? NodeType {
                self._treeCache[node.id] = mnNode
                self.updateRootStatus(node: mnNode)
            } else {
                dlog?.notice("rebuildQuickMap()")
            }
            count += 1
        }, method: .depthFirst, includeSelf:true)
        
        return count
    }
    
    func addToReconstruction(id: IDType, value:ValueType?, parentId:IDType?, depth:DepthToReconstrut) {
        
        guard guardResume(ctx:"addToReconstruction") else { return }
        
        let parentIdSan = (parentId != id) ? parentId : nil
        let prntDesc = parentIdSan != nil ? "\(parentIdSan!)" : "??"
        dlog?.verbose("\(self.TREE_NODE_TYPE_KEY).addToReconstrutionList(id:value:parentId:depth:) id: \(id) parentId: \(prntDesc))")
        
        let item = MNTNReconstructionItem(date: Date.now, id: id, depthToReconstruct: depth, value: value, parentId: parentIdSan)
        self._treeReconstructionWaitingList.append(item)
        if let vparentIdSan = parentIdSan {
            self._treeReconstructionIds.insert(vparentIdSan)
        }
        
        if MNTreeNode<ValueType, IDType>.IS_SHOULD_AUTO_RECONSTRUCT {
            RunLoop.current.schedule {[self] in
                self.attemptReconstruction(context: "addToReconstrutionList.IS_SHOULD_AUTO_RECONSTRUCT", andRebuildQuickMap:true)
            }
        }
    }
    
    func removeFromReconstruction(byId id:IDType) {
        guard guardResume(ctx:"removeFromReconstruction") else { return }
        
        // Remove from the reconstruction list:
        let removedCount = self._treeReconstructionWaitingList.remove { recon in
            recon.id == id && self._treeCache[id] != nil
        }
        self._treeReconstructionIds.remove(id)
        if dlog?.isVerboseActive == true && removedCount > 0 {
            dlog?.verbose("removeFromReconstruction removed \(removedCount) items for id: \"\(id)\". \(self._treeReconstructionIds.count) remaininbg. ")
        }
    }
    
    func attemptReconstruction(context:String, andRebuildQuickMap:Bool = true) {
        guard guardResume(ctx:"attemptReconstruction") else { return }
        
        guard self._treeReconstructionWaitingList.count > 0 else {
            return
        }
        
        let treeCnt = _treeCache.count
        let reconCnt = _treeReconstructionWaitingList.count
        let total = treeCnt + reconCnt
        let rootCnt = _treeRoots.count
        
        // Reconstruct:
        dlog?.verbose("\(self.TREE_NODE_TYPE_KEY) attemptReconstruction | registered: \(treeCnt) waiting: \(reconCnt) total: \(total) / expected: \(_expectedTotal) roots: \(rootCnt)")
        
        var reconstructed : [ReconstructionItem] = []
        for recon in self._treeReconstructionWaitingList {
            dlog?.verbose("\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) id: \"\(recon.id)\" ")
            if let existingNode = self.quickFetch(byId: recon.id) {
                // Node already existed:
                dlog?.note("\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) has a reonstruction job for a node that already exists id:\(recon.id) value:\(recon.value.descOrNil). reconstruction value: \(existingNode.value.descOrNil)")
                self.updateRootStatus(node: existingNode)
                reconstructed.append(recon)
            } else {
                // Node does not exist yet
                var newNode : MNNodeType? = nil
                
                if (recon.depthToReconstruct.depth ?? 0 == 0) && recon.parentId == nil {
                    
                    // Create new node instance - no parent needed
                    newNode = .init(id:recon.id, value:recon.value)
                    dlog?.verbose(symbol: .success, "\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) for a root node \(recon.id)")
                    reconstructed.append(recon)
                    
                } else if let parentId = recon.parentId {
                    
                    // Create new node instance - no parent
                    if let parent = self.quickFetch(byId: parentId) {
                        newNode = .init(id:recon.id, value:recon.value, parent: (parent as! MNNodeType))
                        dlog?.verbose(symbol: .success, "\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) for a node \(recon.id) with existing parent: \(parentId)")
                    } else {
                        dlog?.verbose(symbol: .fail, "\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) for a node \(recon.id) but parent id: \(parentId) still does not exist / or registered in the cache (has \(self._treeCache.count) items)")
                    }
                }
                
                // Add to roots
                if let newNode = newNode, newNode.isRoot {
                    self._treeRoots.add(value: newNode as! NodeType)
                }
            }
            
            if reconstructed.count > 0 {
                let removed = self._treeReconstructionWaitingList.remove(objects: reconstructed)
                dlog?.verbose("\(self.TREE_NODE_TYPE_KEY).attemptReconstruction (ctx: \(context)) removed: \(removed) items.")
            }
        }
        
        // Make sure all items are correctly marked as roots / not roots
        self.updateRootStatuses(nodes: self._treeCache.values)
        var shouldRebuild = andRebuildQuickMap
        if !shouldRebuild {
            shouldRebuild = (_expectedTotal > 0 && total >= _expectedTotal) || MNTreeNode<ValueType, IDType>.IS_SHOULD_AUTO_RECONSTRUCT
        }
        
        // Rebuild quickmap:
        if shouldRebuild {
            self._treeRoots.invalidateNillifiedWeaks()
            for rootNode in self._treeRoots.values {
                let validatedRoot = rootNode.root
                dlog?.verbose("\(self.TREE_NODE_TYPE_KEY).attemptReconstruction will rebuildQuickMap() for root: \(validatedRoot.id)")
                validatedRoot.rebuildQuickMap()
            }
        }
    }
    
    public func invalidate() {
        self._treeRoots.invalidateNillifiedWeaks()
    }
    
}
