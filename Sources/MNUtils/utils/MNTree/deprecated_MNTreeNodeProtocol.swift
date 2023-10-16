//
//  MNTreeNodeProtocol.swift
//  
//
//  Created by Ido on 30/08/2023.
//

/* ===== NOTE: Was deferred in favor of a super class to inherit from ! =========*/
/*
import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNodeProtocol")?.setting(verbose: true)

typealias AnyMNTreeNode = any MNTreeNodeProtocol

public enum MNTreeNodeType {
    case leaf
    case root
    case node
}

public protocol MNTreeNodeProtocol<ValueType, IDType> :  AnyObject, CustomStringConvertible, Hashable {
    // MARK: Types
    associatedtype ValueType : Equatable
    associatedtype IDType : Equatable, Hashable
    typealias ReconstructionItem = MNTNReconstructionItem<ValueType, IDType>
    typealias DepthToReconstrut = MNTNReconstructionItem<ValueType, IDType>.DepthToReconstrut
    
    // MARK: Const
    static var MAX_TREE_DEPTH : Int { get }
    static var IS_SHOULD_AUTO_RECONSTRUCT : Bool { get }
    var IS_SHOULD_AUTO_RECONSTRUCT : Bool { get } // Default implementation calls the static var
    
    // MARK: Static
    static var _treeCache : MNCache<ValueType? IdType, Self> { get set }
    static var _treeReconstructionWaitingList : [ReconstructionItem]  { get set }
    static var _treeRoots : Set<Self> { get set } // for internal use - should be private
    static var treeRoots : Set<Self> { get } // for extenal use - has default implelementation
    
    // MARK: Properties / members
    var value : ValueType? { get set }
    var id : IDType { get set }
    var children : [Self] { get set }
    
    /// NOTE: If implementing parent as getter / setter, implementors need to call setParent to change the tree structure as well
    var parent : Self? { get set }
    
    // MARK: Lifecycle
    init(id:IDType, value:ValueType?) // Implementor must implement
    init(id:IDType, value:ValueType?, parent:Self)
    init?(id:IDType, value:ValueType?, parentID:IDType)
    
    // This was added in the vanilla protocol to allow consumers to "find" this functionality and conform IDType to LosslessStringConvertible if they want
    // The actual implementation that does not throw is only where IDType : LosslessStringConvertible
    init?(id:IDType, value:ValueType?, parentIDString:String)
    
    // MARK: Public
    // Default implementations (overrides not needed)
    var isRoot : Bool { get }
    var isLeaf : Bool { get }
    var isNode : Bool { get }
    var nodeType : MNTreeNodeType { get }
    var depth : Int { get } // depth in the tree from root - distance / amount of parents until the root.
    var root : Self { get }
    
    // Required
    // required init(id newId: IDType, value newValue: ValueType?)
    
    // Functions
    func setParent(_ newParent: Self?)
    
    // Iterations / recursions
    
    @discardableResult
    func recourseChildrenDepthFirst<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                             stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)?,
                                             includeSelf:Bool)->[V]
    
    @discardableResult
    func recourseChildrenBreadthFirst<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                             stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)?,
                                             includeSelf:Bool)->[V]
    
    @discardableResult
    func recourseChildren<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                   method: MNTreeNodeRecursionType,
                                   stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)?,
                                   includeSelf:Bool)->[V]
    
    @discardableResult
    func recourseParents<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                  stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)?,
                                  includeSelf:Bool)->[V]
    
    // Common recursion functions
    
    // Common recursion-dependant functions / computed properties
    var idPath : [IDType] { get }
    var allChildren : [Self] { get }
    var allParents : [Self] { get }
    var allChildrenByDepth : [Int:[Self]] { get }
    var allParentsByDepth : [Int:Self] { get }
    func filterChildrenDowntree(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->[Self]
    func firstChildDowntree(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->Self?
    func filterParents(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool)->[Self]
    func firstParent(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool)->Self?
}

extension MNTreeNodeProtocol /* CustomStringConvertible */ {
    // MARK: CustomStringConvertible
    var description : String {
        return "<\(Self.self) id: \(id) value: \(value.descOrNil.substring(to: 32, suffixIfClipped: "..."))>"
    }
}

extension MNTreeNodeProtocol /* extended initializers, protocol conformance */ {
    
    fileprivate static func addToReconstrutionList(id: IDType, value:ValueType?, parentId:IDType?, depth:DepthToReconstrut) {
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            DispatchQueue.main.async {
                Self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: depth)
            }
            return
        }
        
        let parentIdSan = (parentId != id) ? parentId : nil
        let prntDesc = parentIdSan != nil ? "\(parentIdSan!)" : "??"
        dlog?.verbose("\(Self.self).addToReconstrutionList(id:value:parentId:depth:) id: \(id) parentId: \(prntDesc))")
        let item = MNTNReconstructionItem(date: Date.now, id: id, depthToReconstruct: depth, value: value, parentId: parentIdSan)
        Self._treeReconstructionWaitingList.append(item)
        
        if Self.IS_SHOULD_AUTO_RECONSTRUCT {
            RunLoop.current.schedule {
                Self.attemptReconstruction(context: "addToReconstrutionList.IS_SHOULD_AUTO_RECONSTRUCT", andRebuildQuickMap:true)
            }
        }
    }
    
    fileprivate func addToReconstrutionList(id: IDType, value:ValueType?, parentId:IDType?, depth:DepthToReconstrut) {
        Self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: depth)
    }
    
    init(id: IDType, value: ValueType?, parent newParent: Self) {
        self.init(id: id, value: value)
        self.setParent(newParent)
        self.registerToQuickMap()
        Self.removeFromReconstruction(byId: self.id)
        dlog?.verbose("\(Self.self).init(id: \(id), value: \(value.descOrNil) parent: \(parent.descOrNil))")
    }
    
    init?(id: IDType, value: ValueType?, parentID: IDType) {
        
        dlog?.verbose("\(Self.self).init(id: \(id), value: \(value.descOrNil) parentID: \(parentID))")
        guard id != parentID else {
            // Init where parentId == self.id
            dlog?.note("\(Self.self).init(id: \(id), value: \(value.descOrNil) parentID: \(parentID)) had parentID == self.id !!")
            self.init(id: id, value: value)
            return // Success!
        }
        
        // Init with existing parent:
        if let newParent = Self.quickFetch(byId: parentID) {
            dlog?.verbose(log: .success, "\(Self.self).init(id: \(id), value: \(value.descOrNil) parentID: \(parentID)) parent already existed")
            self.init(id: id, value: value, parent: newParent)
            return // Success!
        }
        
        // Parent does not yet exist:
        Self.addToReconstrutionList(id: id, value: value, parentId: parentID, depth: .unknown)
        return nil // Failed! - will attemp tp "reconstruct" this node later
    }
    
    // This was added in the vanilla protocol to allow consumers to "find" this functionality and conform to LosslessStringConvertible if they want
    // -> Never
    init?(id:IDType, value:ValueType?, parentIDString:String) {
        preconditionFailure("\(Self.self) requires that IDType (see MNTreeNode) conforms to LosslessStringConvertible or Codable.")
    }
    
    // MARK: HasHable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        if let hvalue = value as? any Hashable {
            hasher.combine(hvalue)
        }
    }
    
    // MARK: Equatable
    public static func ==(lhs:Self, rhs:Self)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension MNTreeNodeProtocol where IDType : LosslessStringConvertible {
    init?(id: IDType, value: ValueType?, parentIDString: String) {
        
        guard let parentId = IDType(parentIDString) else {
            preconditionFailure("\(Self.self).init(id:value:parentIDString:) could not create an \(IDType.self) instance from:(parentIDString) for value: \(value.descOrNil)")
        }
        
        guard let existingParent = Self.quickFetch(byId: parentId) else {
            Self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: .unknown) // depth is tentatively one
            return nil
        }
        
        self.init(id: id, value: value, parent: existingParent)
        dlog?.verbose(log:.success, "\(Self.self).init(id: \(id), value: \(value.descOrNil) parentIDString: \(parentIDString) (parent already exited)")
    }
}

extension MNTreeNodeProtocol /* Default implementations */ {
    
    var IS_SHOULD_AUTO_RECONSTRUCT : Bool {
        // Default implementation calls the static var
        return Self.IS_SHOULD_AUTO_RECONSTRUCT
    }
    
    // MARK: Private
    private func _recourseChildren<ResultType : Any>(_ block: (_ node:Self,_ depth:Int)->MNResumeStopTuple<ResultType>,
                                            includeSelf:Bool = false,
                                            recursionType:MNTreeNodeRecursionType,
                                            recursionDepth:Int, nodeDepth:Int)->MNResumeStopTuple<[ResultType]>  {
        
        guard recursionDepth <= Self.MAX_TREE_DEPTH && recursionDepth < Self.MAX_TREE_DEPTH else {
            dlog?.note("\(Self.self) _recourseChildren \(recursionType.description) recursion depth exceeded MAX_TREE_DEPTH \(Self.MAX_TREE_DEPTH)")
            return MNResumeStopTuple.stopEmpty
        }
        var result : [ResultType] = []
        
        // Add starting node or depth-first children
        if (recursionDepth == 0 && includeSelf) || (recursionType == .depthFirst) {
            let rsTuple = block(self, nodeDepth)
            if let value = rsTuple.value { result.append(value) }
            
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        // Add breadth-first children
        if recursionType == .breadthFirst {
            // We get the children's results before recoursing to next level
            for child in children {
                let rsTuple = block(child, nodeDepth + 1)
                if let val = rsTuple.value {
                    result.append(val)
                }
                
                if rsTuple.instruction == .stop {
                    return MNResumeStopTuple.stop(result)
                }
            }
        }
        
        // Recourse children
        for child in children {
            let rsTuple = child._recourseChildren(block, includeSelf:false, recursionType: recursionType, recursionDepth:recursionDepth + 1, nodeDepth: nodeDepth + 1)
            if let val = rsTuple.value {
                result.append(contentsOf: val)
            }
            if rsTuple.instruction.isStop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        return MNResumeStopTuple.resume(result)
    }
    
    private func _recourseParents<ResultType : Any>(_ block: (_ node:Self,_ depth:Int)->MNResumeStopTuple<ResultType>, includeSelf:Bool = false, recursionDepth:Int, nodeDepth:Int)->MNResumeStopTuple<[ResultType]> {
        guard nodeDepth <= Self.MAX_TREE_DEPTH && recursionDepth <= Self.MAX_TREE_DEPTH &&
              nodeDepth >= 0 && recursionDepth >= 0 else {
            dlog?.note("\(Self.self) _recourseParents recursion depth exceeded MAX_TREE_DEPTH \(Self.MAX_TREE_DEPTH)")
            return .stopEmpty
        }
        
        var result : [ResultType] = []
        if recursionDepth > 0 || includeSelf {
            let rsTuple = block(self, nodeDepth)
            if let value = rsTuple.value {
                result.append(value)
            }
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        if let parent = parent {
            let rsTuple = parent._recourseParents(block, includeSelf:false, recursionDepth:recursionDepth + 1, nodeDepth: nodeDepth - 1)
            if let val = rsTuple.value {
                result.append(contentsOf: val)
            }
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        return MNResumeStopTuple.resume(result)
    }
    
    
    // MARK: Default implementations
    static var MAX_TREE_DEPTH : Int { return 32 }
    static var IS_SHOULD_AUTO_RECONSTRUCT : Bool { return false }
    
    func addChild(_ node: Self) {
        self.children.appendIfNotAlready(node)
        if node.parent != self {
            node.parent = self
        }
    }
    
    func removeChild(_ node: Self) {
        self.children.remove(elementsEqualTo: node)
        if node.parent == self {
            node.parent = nil
        }
    }
    
    func setParent(_ newParent:Self?) {
        let toParent = newParent
        let fromParent = self.parent
        
        if fromParent?.id != toParent?.id {
            
            self.parent = newParent
            
            // Will change the children arrays accordingly:
            toParent?.addChild(self)
            fromParent?.removeChild(self)
            
            if fromParent == nil || toParent == nil {
                // We need to rebuild the rootList
            }
        }
    }
    
    var isRoot : Bool {
        return self.parent == nil
    }
    
    var isLeaf : Bool {
        return self.children.count == 0
    }
    
    var isNode : Bool {
        !self.isRoot && !self.isLeaf
    }
    
    var nodeType : MNTreeNodeType {
        if self.isRoot { return .root }
        if self.isLeaf { return .leaf }
        return .node
    }
    
    var root : Self {
        self.recourseParents { node, depth in
            if node.isRoot {
                return node
            }
            return nil
        }.first ?? self
    }
    
    // MARK: depth related results
    var depth : Int {
        return self.allParents.count
    }
    
    // Iterations / recursions
    @discardableResult
    func recourseChildrenDepthFirst<V : Any>(_ block: (_ node:Self, _ depth:Int)->V?,
                                             stopTest:((_ node:Self,_ depth:Int, _ result: V?)->Bool)? = nil,
                                             includeSelf:Bool = false)->[V] {
        let rsTuple = self._recourseChildren({ node, depth in
            var result = MNResumeStopTuple.resume(block(node, depth))
            if stopTest?(node, depth, result.value) == true {
                result.changeToStop()
            }
            return result
        }, recursionType: .depthFirst, recursionDepth: 0, nodeDepth: self.depth)
        
        // Log if stooped
        if dlog?.isVerboseActive == true && rsTuple.instrutionIsStop {
            dlog?.verbose(log: .note, "recourseChildrenWidthFirst for \(self) was STOPPED!")
        }
        return rsTuple.value ?? []
    }
    
    @discardableResult
    func recourseChildrenBreadthFirst<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                               stopTest:((_ node:Self,_ depth:Int, _ result : V?)->Bool)? = nil,
                                             includeSelf:Bool = false)->[V] {
        let rsTuple = self._recourseChildren({ node, depth in
            var result = MNResumeStopTuple.resume(block(node, depth))
            if stopTest?(node, depth, result.value) == true {
                result.changeToStop()
            }
            return result
            
        }, includeSelf:includeSelf, recursionType: .breadthFirst, recursionDepth: 0, nodeDepth: self.depth)
        
        // Log if stooped
        if dlog?.isVerboseActive == true && rsTuple.instrutionIsStop {
            dlog?.verbose(log: .note, "recourseChildrenWidthFirst for \(self) was STOPPED!")
        }
        return rsTuple.value ?? []
    }
    
    @discardableResult
    func recourseChildren<V : Any>(_ block:(_ node:Self, _ depth:Int)->V?,
                                   method: MNTreeNodeRecursionType,
                                   stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)?,
                                   includeSelf:Bool)->[V] {
        switch method {
        case .depthFirst:   return self.recourseChildrenDepthFirst(block, stopTest: stopTest, includeSelf: includeSelf)
        case .breadthFirst: return self.recourseChildrenBreadthFirst(block, stopTest: stopTest, includeSelf: includeSelf)
        }
    }
    @discardableResult
    func recourseParents<V : Any>(_ block:(_ node:Self,_ depth:Int)->V?,
                                  stopTest:((_ node:Self,_ depth:Int, _ result:V?)->Bool)? = nil,
                                  includeSelf:Bool = false)->[V] {
        // NOTE: DO NOT USE self.depth in this function, because it also uses recourseParents.
        var nodeDepth = 0
        var currentNode = self
        while currentNode.parent != nil {
            nodeDepth += 1
            if let newVal = currentNode.parent {
                currentNode = newVal
            }
        }
        
        let rsTuple = self._recourseParents({ node, depth in
            var result = MNResumeStopTuple.resume(block(node, depth))
            if stopTest?(node, depth, result.value) == true {
                result.changeToStop()
            }
            return result
        }, includeSelf:includeSelf, recursionDepth: 0, nodeDepth: nodeDepth)
        
        // Log if stooped
        if dlog?.isVerboseActive == true && rsTuple.instrutionIsStop {
            dlog?.verbose(log: .note, "recourseParents for \(self) was STOPPED!")
        }
        return rsTuple.value ?? []
    }
    
    // Common recursion-dependant functions / computed properties
    var idPath : [IDType] {
        return self.recourseParents({ node, depth in
            return node.id
        }, includeSelf: true)
    }
    
    var allChildren : [Self] {
        return self.recourseChildrenDepthFirst({ node, depth in
            return node
        }, includeSelf: false)
    }
    
    var allParents : [Self] {
        return self.recourseParents({ node, depth in
            return node
        }, includeSelf: false)
    }
    
    var allChildrenByDepth : [Int:[Self]] {
        let results : [(Int, Self)] = self.recourseChildrenDepthFirst({ node, depth in
            return (depth, node)
        }, includeSelf: false)
        
        let result = results.toDictionaryOfArrays { elem in
            return elem.0
        } arrayItemForItem: { elem in
            return elem.1
        }

        return result
    }
    
    var allParentsByDepth : [Int:Self] {
        return self.allParents.toDictionary { element in
            element.depth
        } itemForItem: { key, element in
            element
        }
    }
    
    
    func filterChildrenDowntree(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->[Self] {
        return self.recourseChildren({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, method: method, stopTest: nil, includeSelf: includeSelf)
    }
    
    func firstChildDowntree(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->Self? {
        return self.recourseChildren({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, method: method, stopTest: nil, includeSelf: includeSelf).first
    }
    
    func filterParents(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool)->[Self] {
        return self.recourseParents({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, stopTest: nil, includeSelf: includeSelf)
    }
    
    func firstParent(where block:(_ node:Self, _ depth:Int)->Bool, includeSelf:Bool)->Self? {
        return self.recourseParents({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, stopTest: nil, includeSelf: includeSelf).first
    }
}

extension MNTreeNodeProtocol where IDType : Hashable {
    
    var childrenById : [IDType:Self] {
        return self.children.nodesById
    }
    
    var allChildrenById : [IDType:Self] {
        return self.allChildren.nodesById
    }
    
    var allParentsById : [IDType:Self] {
        return self.allParents.nodesById
    }
    
}

extension Sequence where Element : MNTreeNodeProtocol {
    
    var ids : [Element.IDType] {
        return self.map { node in
            node.id
        }
    }
    
    var values : [Element.ValueType] {
        return self.compactMap { node in
            node.value
        }
    }
}

extension Sequence where Element : MNTreeNodeProtocol, Element.IDType : Hashable {
    var nodesById : [Element.IDType:Element] {
        return self.toDictionary { element in
            element.id
        }
    }
}

// ======================== as TreeRootNode =============================

extension MNTreeNodeProtocol /* reconstruction & quickMap */ {
    
    fileprivate static func removeFromReconstruction(byId id:IDType) {
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            DispatchQueue.main.async {
                Self.removeFromReconstruction(byId: id)
            }
            return
        }
        
        // Remove from the reconstruction list:
        let removedCount = Self._treeReconstructionWaitingList.remove { recon in
            recon.id == id
        }
        if removedCount > 0 {
            dlog?.info("\(Self.self).removeFromReconstruction removed \(removedCount) items for id: \"\(id)\" ")
        }
    }
    
    static func attemptReconstruction(context:String, andRebuildQuickMap:Bool = true) {
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            DispatchQueue.main.async {[context] in
                Self.attemptReconstruction(context:context, andRebuildQuickMap:andRebuildQuickMap)
            }
            return
        }
        
        guard Self._treeReconstructionWaitingList.count > 0 else {
            return
        }
        
        // Reconstruct:
        dlog?.verbose("\(Self.self).attemptReconstruction (ctx: \(context)) list contains \(Self._treeReconstructionWaitingList.count) ")
        
        var rootNodes : [Self] = []
        var reconstructed : [ReconstructionItem] = []
        for recon in Self._treeReconstructionWaitingList {
            dlog?.verbose("\(Self.self).attemptReconstruction (ctx: \(context)) for \(Self.self) id: \"\(recon.id)\" ")
            if let existingNode = Self.quickFetch(byId: recon.id) {
                dlog?.note("\(Self.self).attemptReconstruction (ctx: \(context)) has a reonstruction job for a node that already exists id:\(recon.id) value:\(recon.value.descOrNil). reconstruction value: \(existingNode.value.descOrNil)")
                rootNodes.append(existingNode.root)
                reconstructed.append(recon)
            } else {
                // Does not exist yet
                var newNode : Self? = nil
                
                // Create new node instance:
                if (recon.depthToReconstruct.depth ?? 0 == 0) && recon.parentId == nil {
                    newNode = Self.init(id:recon.id, value:recon.value)
                    dlog?.verbose(log:.success, "\(Self.self).attemptReconstruction (ctx: \(context)) for a root node \(newNode.descOrNil)")
                    reconstructed.append(recon)
                } else if let parentId = recon.parentId {
                    if let parent = self.quickFetch(byId: parentId) {
                        newNode = Self.init(id:recon.id, value:recon.value, parent: parent)
                        dlog?.verbose(log:.success, "\(Self.self).attemptReconstruction (ctx: \(context)) for a node \(newNode.descOrNil) with existing parent by id: \(parent.id)")
                    } else {
                        dlog?.verbose(log:.fail, "\(Self.self).attemptReconstruction (ctx: \(context)) for a node \(newNode.descOrNil) but parent node id: \(parentId) still does not exist / or registered in the cache (has \(Self._treeCache.count) items)")
                    }
                }
                
                // Keep all root nodes in current iteration
                if let newNode = newNode {
                    rootNodes.append(newNode.root)
                }
            }
        }
        
        if reconstructed.count > 0 {
            let removed = Self._treeReconstructionWaitingList.remove(objects: reconstructed)
            dlog?.verbose("\(Self.self).attemptReconstruction (ctx: \(context)) removed: \(removed) items.")
        }
        
        // Rebild quickmap:
        if andRebuildQuickMap {
            for rootNode in rootNodes {
                if rootNode.isRoot { // JIC
                    dlog?.verbose("\(Self.self).attemptReconstruction (ctx: \(context)) calling \"\(rootNode.id)\".rebuildQuickMap()")
                    rootNode.rebuildQuickMap()
                }
            }
        }
    }
    
    func attemptReconstruction(context:String, andRebuildQuickMap:Bool = true) {
        Self.attemptReconstruction(context: context + "*", andRebuildQuickMap:andRebuildQuickMap)
    }
    
    func rebuildQuickMap() {
        
        // Trampoline
        guard DispatchQueue.isMainQueue else {
            let sself = self as AnyObject
            DispatchQueue.main.async {[weak sself] in
                if let zelf = sself {
                    let selfz = zelf as! Self
                    selfz.rebuildQuickMap()
                }
            }
            return
        }
        
        // Actual work:
        var newQuickMap : [IDType : Self] = [:]
        let rootNode = self.root // Will return self if no parent
        dlog?.verbose("\(Self.self).rebuildQuickMap() starting root: \"\(rootNode.id)\" ")
        
        rootNode.recourseChildrenDepthFirst({ node, depth in
            dlog?.verbose("\(Self.self).rebuildQuickMap()    found id: \"\(node.id)\"")
            newQuickMap[node.id] = node
        }, includeSelf: true)
        
        let prevCount = Self._treeCache.count
        Self._treeCache.replaceWith(dictionary: newQuickMap)
        let newCount = Self._treeCache.count
        if newCount != prevCount {
            dlog?.success("\(Self.self).rebuildQuickMap DONE cache count: \(newCount)")
        }
   }
    
    func registerToQuickMap() {
        let prev = Self._treeCache[self.id]
        Self._treeCache[self.id] = self
        if prev == nil || prev != self {
            dlog?.info("registerToQuickMap() : \(self.id) | cache count: \(Self._treeCache.count)")
        }
    }
    
    func unregisterFromQuickMap() {
        Self._treeCache[self.id] = nil
    }
    
    fileprivate static func quickFetch(byIdString idString:String?) -> Self? where IDType : LosslessStringConvertible {
        guard let idStr = idString, let id = IDType(idStr) else {
            dlog?.note("quickFetch(byIdString:) recieved a nil string")
            return nil
        }
        
        return self.quickFetch(byId:id)
    }
    
    fileprivate static func quickFetch(byId id:IDType?) -> Self? {
        guard let id = id else {
            dlog?.note("quickFetch(byId:) recieved a nil id")
            return nil
        }
        
        return Self._treeCache[id] // any MNTreeNode< !! MAKE SURE ORDER OF TYPES IS CORRECT !! ValueType, ?? IDType ??  ValueType>
    }
    
    // Convenience:
    fileprivate func quickFetch(byId id:IDType?) -> Self? {
        Self.quickFetch(byId: id)
    }
    
    fileprivate func quickFetch(byIdString idString:String?) -> Self? where IDType : LosslessStringConvertible {
        Self.quickFetch(byIdString: idString)
    }
}

extension MNTreeNodeProtocol /* treeRoots */ {
    static var treeRoots : Set<Self> {
        return _treeRoots
    }
}
*/
