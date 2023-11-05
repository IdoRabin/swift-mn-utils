//
//  MNTreeNode.swift
//  
//
//  Created by Ido on 07/09/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNode")?.setting(verbose: false)
fileprivate let dlogDecode : DSLogger? = DLog.forClass("MNTreeNode |dec|")?.setting(verbose: true)

public enum MNTreeNodeType : String, Codable, CaseIterable {
    case leaf
    case root
    case node
    
    var treeStructDescStr : String {
        switch self {
        case .root: return "+"
        case .node: return "-"
        case .leaf: return "^"
        }
    }
}


// Coding Keys for encoder.userInfo
fileprivate let _MNTN_depthCodingUIKey = CodingUserInfoKey(rawValue: "MNTreeNode.depth")!
fileprivate let _MNTN_is_flat_CodingUIKey = CodingUserInfoKey(rawValue: "MNTreeNode.is_flat")!

// NOTE:
// ValueType : Hashable // Needed for some caching operations
// IDType : Hashable // Needed for some caching operations
/// A tree node, wrapping a generic value, able to manage many versatile actions and has multiple extension for encodinhg, identifiable and more.
public class MNTreeNode<ValueType: Hashable, IDType: Hashable> :  CustomStringConvertible, Hashable, MNTreeNodeProtocol {
    
    // MARK: Types
    typealias ReconstructionItem = MNTNReconstructionItem<ValueType, IDType>
    typealias DepthToReconstrut = MNTNReconstructionItem<ValueType, IDType>.DepthToReconstrut
    public typealias SelfType = MNTreeNode<ValueType, IDType>
    public typealias IDType = IDType
    public typealias ValueType = ValueType
    
    // MARK: Coding keys
    enum CodingKeys : String, CodingKey, CaseIterable {
        case id = "id"
        case value = "value"
        case children = "nodes" // children"
        case childrenIds = "node_ids" // "children_ids"
        case parentId = "parent_id"
        case isCached = "is_cached"
        case totalCount = "total_count"
        case flatTree = "flat_tree"
        case fullTree = "tree"
        
//        case idType = "id_type"
//        case valueType = "value_type"
        case treeNodeTypeKey = "tree_node_type_key" //
        
        case allTrees = "all_trees"
        
        case nodeInfo = "node_info"
        
        case treeInfo = "tree_info"
        
        var stringValue: String {
            let prefix = MNTreeConfig.nodeKeysPrefix // this allows to distinguish in the JSON between node Value attributes and tree structure attributes.
            return prefix + self.rawValue
        }
        
        var debugDescription: String {
            let prefix = MNTreeConfig.nodeKeysPrefix // this allows to distinguish in the JSON between node Value attributes and tree structure attributes.
            return prefix + self.rawValue
        }
    }
    
    // For use only on root:
    enum RootInfoCodingKeys : String, CodingKey, CaseIterable {
        case idType = "mn_generic_id_type"
        case valueType = "mn_generic_value_type"
        case totalItemsCount = "mn_total_items_count"
    }
    
    enum NodeInfoCodingKeys : String, CodingKey, CaseIterable {
        case nodeRoleInTree = "node_role_in_tree"
        case nodeDepth = "node_depth"
        case nodeHash = "node_hash"
    }
    
    // Override MNTreeConfig
    public static var MNTN_depthCodingUIKey : CodingUserInfoKey { _MNTN_depthCodingUIKey }
    public static var MNTN_is_flat_CodingUIKey : CodingUserInfoKey { _MNTN_depthCodingUIKey }
    
    // MARK: Const
    public static var MAX_TREE_DEPTH : Int { return 32 }
    public static var IS_SHOULD_AUTO_RECONSTRUCT : Bool { return false }
    public var IS_SHOULD_AUTO_RECONSTRUCT : Bool { return Self.IS_SHOULD_AUTO_RECONSTRUCT }
    public static var IS_CACHED : Bool { return true }
    
    // MARK: Properties / members
    public var value : ValueType? = nil
    private (set) public var id : IDType
    private (set) public var children : [SelfType] = []
    private (set) public var parent : SelfType? = nil
    
    // MARK: Public computed vars
    // Default implementations (overrides not needed)
    public var isRoot : Bool {
        return self.parent == nil
    }
    
    public var isLeaf : Bool {
        return self.children.count == 0
    }
    
    public var isNode : Bool {
        !self.isRoot && !self.isLeaf
    }
    
    public var nodeType : MNTreeNodeType {
        if self.isRoot { return .root }
        if self.isLeaf { return .leaf }
        return .node
    }
    
    var hasChildren : Bool {
        return self.children.count > 0
    }
    
    var hasParent : Bool {
        return self.parent != nil
    }
    
    public var root : SelfType {
        self.recourseParents { node, depth in
            if node.isRoot {
                return node
            }
            return nil
        }.first ?? self
    }
    
    // MARK: CustomStringConvertible
    public var description : String {
        let typ = self.nodeType.rawValue
//        let childs = self.hasChildren ? " children: " +  self.children.idDescriptions.descriptionsJoined : " chlidren: 0"
//        if let parentId = self.parent?.id {
//            return "<\(Self.self) id: \"\(id)\" |\(typ)| value: \"\(value.descOrNil.substring(to: 32, suffixIfClipped: "..."))\"\(childs) parentId: \"\(parentId)\" >"
//        } else {
//            return "<\(Self.self) id: \"\(id)\" |\(typ)| value: \"\(value.descOrNil.substring(to: 32, suffixIfClipped: "..."))\"\(childs) >"
//        }
        return "<\(Self.self) id: \"\(id)\" |\(typ)| \(MemoryAddress(of: self).description) >"
    }
    
    public func treeDescription() -> [String] {
        return self.treeDescription(depth: 0)
    }
    
    private func treeDescription(depth:Int = 0) -> [String] {
        guard depth < Self.MAX_TREE_DEPTH else {
            dlog?.note("treeDescription(depth:\(depth) recursion or tree depth too big!")
            return []
        }
        
        var result : [String] = ["   ".repeated(times: depth + 1) + self.nodeType.treeStructDescStr + " " + self.description]
        if self.children.count > 0 {
            let sortedChildren = MNUtils.debug.IS_DEBUG ? self.children.sorted(byChildrenCountAscending: true) : self.children
            for child in sortedChildren {
                result.append(contentsOf: child.treeDescription(depth: depth + 1))
            }
        }
        
        return result
    }
    
    // MARK: Equatable
    public static func ==(lhs:SelfType, rhs:SelfType)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        // NOTE: Non-persistant across sessions or instances!
        hasher.combine(MemoryAddress(of: self).rawValue)
        hasher.combine(id)
        hasher.combine(value)
        hasher.combine(parent?.id)
        hasher.combine(children.ids)
    }
    
    // MARK: Mutate id before init for various protocol conformances
    private static func idForIdentifiable(value:ValueType?)->IDType? {
        return nil
    }
    
    private static func idForMNUIDable(value:ValueType?)->IDType? {
        if (ValueType.self is MNUIDable) {
            dlog?.note("Type \(Self.self) has an IDType of MNUID, consider if ValueType should be MNUIDable?")
        }
        return nil
    }
    
    private static func idForMNUIDType(value:ValueType?)->IDType? {
        return nil
    }
    
    private static func idForIdentifiable(value:ValueType?)->IDType? where ValueType : Identifiable, IDType == ValueType.ID {
        return value?.id
    }
    
    private func idForMNUIDable(value:ValueType?)->IDType? where ValueType : MNUIDable, IDType == MNUID {
        return value?.mnUID
    }
    
    // MARK: Lifecycle
    required public init(id: IDType, value: ValueType?, parent newParent: SelfType? = nil) {
        let anId : IDType =
            Self.idForIdentifiable(value:value) ??
            Self.idForMNUIDable(value:value) ??
            id
        
        self.id = anId
        self.value = value
        if let newParent = newParent {
            self.setParent(newParent)
        }
        
        self.registerToQuickMap()
        UnknownMNTreeDecodingObj.registerNodeType(key: "\(type(of:self))", node: self)
        
        Self.removeFromReconstruction(byId: self.id)
        dlog?.verbose("\(Self.self).init(id: \(id), value: \(value.descOrNil) parent: \(parent.descOrNil))")
    }
        
    // Codable?
    public required init(from decoder: Decoder) throws {
        let msg = "\(Self.self) can only be decoded when value type: \(ValueType.self) and IDType: \(IDType.self) are Codable!"
        dlogDecode?.warning(msg)
        throw MNError(code: .misc_failed_decoding, reason: msg)
    }
    
    private static func getDecodeDepth(decoder: Decoder, depth:Int = 0) throws ->Int {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if container.allKeys.contains(anyOf: [.flatTree, .allTrees]) {
                return depth
            }
            
            return try Self.getDecodeDepth(decoder: try container.superDecoder(), depth: depth + 1)
        } catch {
            
        }
        return depth
    }
    
    private static func getIsTree(decoder: Decoder, depth:Int = 0)->(Bool /* isTree */, Bool /* isFlatTree */) {
        var isTree = false
        var isFlatTree = false
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let allKeys = container.allKeys
            isTree = allKeys.contains(anyOf: [.flatTree, .fullTree])
            if !isTree {
                return Self.getIsTree(decoder: try container.superDecoder(), depth: depth + 1)
            } else {
                dlogDecode?.success(">> found isTree. isFlatTree: \(isFlatTree) depth: \(depth)")
                isFlatTree = allKeys.contains(.flatTree)
            }
        } catch { // let error {
            // dlogDecode?.warning("Failed finding super decoder with .treeNodeTypeKey. depth: \(depth) error: \(error.description)")
        }
        return (isTree, isFlatTree)
    }
    
    private static func getNodeTypeKey(decoder: Decoder, depth:Int = 0)->String? {
        var result : String? = nil
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            result = try container.decodeIfPresent(String.self, forKey: .treeNodeTypeKey)
            if result == nil {
                result = Self.getNodeTypeKey(decoder: try container.superDecoder(), depth: depth + 1)
            }
            if result != nil {
                dlogDecode?.success(">> found getNodeTypeKey: \(result.descOrNil) depth: \(depth)")
            }
        } catch { // let error {
            // dlogDecode?.warning("Failed finding super decoder with .treeNodeTypeKey.  depth: \(depth) error: \(error.description)")
        }
        
        return result
    }
    
    public required init(from decoder: Decoder) throws where Self: Codable, ValueType : Codable, IDType : Codable {
        // Actual basic implementation init(from decoder) for MNTreeNode
        let depth = try Self.getDecodeDepth(decoder:decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nodeTypeKey : String? = try container.decodeIfPresent(String.self, forKey: .treeNodeTypeKey) ?? Self.getNodeTypeKey(decoder: decoder)
        let allKeys = container.allKeys
        let treeInf = Self.getIsTree(decoder: decoder)
        let isTree = treeInf.0
        var isFlatTree = treeInf.1
        var treeTypeStr = "SINGLE"
        if isTree {
            treeTypeStr = isFlatTree ? "FLAT" : "FULL"
        }
        let logPrefix = (dlog != nil) ? "\(Self.self) decode \(treeTypeStr) @\(depth)" : "?"
        
        if nodeTypeKey != nil {
            guard nodeTypeKey == Self.TREE_NODE_TYPE_KEY else {
                let msg = "\(Self.self) decoding failed depth:\(depth): tree type key mismatch: \(nodeTypeKey.descOrNil) != \(Self.TREE_NODE_TYPE_KEY)"
                dlogDecode?.warning(msg)
                throw MNError(code: .misc_failed_decoding, reason: msg)
            }
        }
        
        // Decode self properties from the correct container:
        if isTree {
            isFlatTree = allKeys.contains(elementEqualTo: .flatTree)
            dlogDecode?.info("\(logPrefix) Decoding START")
        }
        
        var treeInstances : [IDType:SelfType] = [:]
        var childParentIds : [IDType:IDType?] = [:]
        
        // Decode self:
        // Set required properties:
        var keyedContainer = container // for single node
        if isTree {
            keyedContainer = try container.nestedContainer(keyedBy: Self.CodingKeys, forKey: isFlatTree ? .flatTree :  .fullTree)
        }
        self.id = try keyedContainer.decode(IDType.self, forKey: .id)
        self.value = try keyedContainer.decodeIfPresent(ValueType.self, forKey: .value)
        self.parent = nil  // will be assinged later
        
        treeInstances[self.id] = self
        childParentIds[self.id] = nil
        
        func decodeChildren(unkeyedContainer: inout UnkeyedDecodingContainer) throws {
            let totalExpected = max(unkeyedContainer.count ?? 0, childParentIds.count)
            var totalCreated = 0
            dlogDecode?.info("\(logPrefix) decodeChildren expecting \(totalExpected) child nodes:")
            while !unkeyedContainer.isAtEnd {
                let node = try unkeyedContainer.decode(SelfType.self)
                treeInstances[node.id] = node
                totalCreated += 1
            }
        }
        
        func decodeChildrenTree(unkeyedContainer: inout UnkeyedDecodingContainer, depth:Int = 0, parentID:IDType? = nil) throws {
            let totalExpected = unkeyedContainer.count
            var totalFound = 0
            while !unkeyedContainer.isAtEnd {
                let instanceContainer = try unkeyedContainer.nestedContainer(keyedBy: Self.CodingKeys)
                let id : IDType? = try instanceContainer.decodeIfPresent(IDType.self, forKey: .id)
                var parentId = parentID
                if let id = id {
                    if parentId == nil {
                        parentId = try instanceContainer.decodeIfPresent(IDType.self, forKey: .parentId)
                    }
                    childParentIds[id] = parentId
                    totalFound += 1
                    if parentId == nil || parentId == .none {
                        dlog?.note("node: \(id) has no parent!")
                    }
                }
                
                if instanceContainer.allKeys.contains(elementEqualTo: .children) {
                    var unkeyedContainer = try instanceContainer.nestedUnkeyedContainer(forKey: .children)
                    try decodeChildrenTree(unkeyedContainer: &unkeyedContainer, depth: depth + 1, parentID: id)
                }
            }
            dlogDecode?.success("\(logPrefix) decodeChildrenTree found \(totalFound)/\(totalExpected.descOrNil) ided nodes at depth: \(depth)")
        }
        
        // Decode child nodes:
        if keyedContainer.allKeys.contains(.children) {
            var unkeyedContainer = try keyedContainer.nestedUnkeyedContainer(forKey: .children)
            do {
                // Will decode all children (flat or full tree):
                DLog.indentStart(logger: dlogDecode)
                try decodeChildrenTree(unkeyedContainer: &unkeyedContainer)
                unkeyedContainer = try keyedContainer.nestedUnkeyedContainer(forKey: .children)
                try decodeChildren(unkeyedContainer: &unkeyedContainer)
                DLog.indentEnd(logger: dlogDecode)
            } catch let error {
                let msg = "Failed decoding instance in \(treeTypeStr) tree: \(Self.self) depth:\(depth) error: \(error.description)"
                dlog?.warning(msg)
                throw MNError(code: .misc_failed_decoding, reason: msg)
            }
        }
        
        // Set parent and children:
        for (achildId, aparentId) in childParentIds {
            if let aparentId = aparentId, let achild = treeInstances[achildId], let aparent = treeInstances[aparentId] {
                achild.setParent(aparent)
            }
        }
            
        dlogDecode?.info("\(logPrefix) Decoded | id: \"\(self.id)\" |\(self.nodeType.rawValue)| value: \"\(self.value.descOrNil)\" ")
    }
    
    public convenience init?(id: IDType, value: ValueType?, parentID: IDType) {
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
        
        // Case where parent does not yet exist:
        Self.addToReconstrutionList(id: id, value: value, parentId: parentID, depth: .unknown)
        return nil // Failed! - will attemp tp "reconstruct" this node later
    }
    
    // This was added in the vanilla protocol to allow consumers to "find" this functionality and conform to LosslessStringConvertible if they want
    // -> Never
    public convenience init?(id:IDType, value:ValueType?, parentIDString:String) {
        preconditionFailure("\(Self.self) requires that IDType (see MNTreeNode) conforms to LosslessStringConvertible or Codable.")
    }
    
    deinit {
        dlog?.info("\(self).deinit")
    }
    
    // MARK: private
    
    @discardableResult
    func validateTreeIntegrity()->[MNError] {
        var result : [MNError] = []
        var visitedIds = Set<IDType>()
        var duplicateIds = Set<IDType>()
        self.root.iterateChildrenDowntree({ node, depth in
            if !visitedIds.contains(node.id) {
                visitedIds.update(with: node.id)
            } else {
                duplicateIds.update(with: node.id)
            }
            return .resume
        }, includeSelf: true, method: .breadthFirst)
        
        if duplicateIds.count > 0 {
            let msg = "\(Self.self) tree sturcture has duplicate nodes in different areas of the tree: \(duplicateIds.count)"
            result.append(MNError(code: .misc_bad_input, reason: msg))
            dlog?.warning(msg + "\n" + self.root.treeDescription().descriptionLines)
        }
        
        return result
    }
    
    @discardableResult
    func validateTreeIntegrityIfNeeded()->[MNError] {
        guard self.config.isValidatesPossibleRecursiveIssues else {
            return []
        }
        return self.validateTreeIntegrity()
    }
    // MARK: depth related results
    public var depth : Int {
        return self.allParents.count
    }
    
    // MARK: Tree mgmt Functions
    func setParent(_ newParent:SelfType?) {
        guard newParent != self else {
            dlog?.warning("\(self.TREE_NODE_TYPE_KEY) : setParent set the parent to self! this is not allowed (infinite recursions and bad things can happen)!")
            return
        }
        
        let toParent = newParent
        let fromParent = self.parent
        
        if fromParent?.id != toParent?.id {
            
            self.parent = newParent
            
            // Will change the children arrays accordingly:
            fromParent?.removeChild(self)
            toParent?.addChild(self)
            
            // TODO: Check the rationale behind this.
            if fromParent == nil || toParent == nil {
                // We need to rebuild the rootList
                self.removeFromReconstruction(byId: self.id)
            }
        }
    }
    
    func addChildren(_ nodes: [SelfType]) {
        
        // Assumes SelfType is Equatable
        let newNodes = nodes.removing(elementsEqualTo: self)
        if newNodes.count < nodes.count {
            dlog?.warning("\(self.TREE_NODE_TYPE_KEY) : addChildren attempted to add a child that is self. this is not allowed! (infinite recursions and bad things can happen)!")
        }
        
        // Recurive validations:
        if config.isValidatesPossibleRecursiveIssues {
            // CPU intensive: recursion
            let existingIds = self.root.allChildren(includeSelf: true).ids.removing(objects: self.children.ids)
            let newIds = nodes.ids
            let intersection = existingIds.intersection(with: newIds)
            if intersection.count > 0 {
                dlog?.warning("\(self.TREE_NODE_TYPE_KEY) : addChildren attempted to add nodes as children of [\(self.id)] that are already in the tree! existing: \(intersection)")
            }
        }
        
        // Append if not already to the array:
        self.children = newNodes.union(with: self.children)
        for anode in newNodes {
            if anode.parent != self {
                anode.setParent(self)
            } else {
                // node paretn was already self
            }
        }
    }
    
    func addChild(_ node: SelfType) {
        self.addChildren([node])
    }
    
    func removeChildren(_ nodes: [SelfType]) {
        
        var rootNode : SelfType? = nil
        if config.isValidatesPossibleRecursiveIssues {
            rootNode = self.root
        }
        
        let nodesToRemove = nodes.intersection(with: self.children)
        if nodesToRemove.count < nodes.count {
            dlog?.note("removeChildren recieved some nodes to remove (\(nodes.removing(objects: nodesToRemove).ids.descriptionJoined)) that are NOT children of self: \"\(self.id)\"")
        }
        guard nodesToRemove.count > 0 else {
            dlog?.note("removeChildren has 0 nodes to remove!")
            return
        }
        
        // Remove all instances equal to any in "nodes" array
        // Assumes Equatable
        let removedCount = self.children.remove(objects: nodesToRemove)
        
        if config.isValidatesPossibleRecursiveIssues {
            if removedCount < nodes.count {
                
            }
            if rootNode != self.root {
                dlog?.warning("Removed a node that was also a parent, this means the tree structure was broken in an unintended place.")
            }
        }
        
        for node in nodes {
            if node.parent != nil {
                node.setParent(nil)
            }
        }
    }
    
    // Convenience
    func removeChild(_ node: SelfType) {
        self.removeChildren([node])
    }
    
    func moveToNewParent(_ newParent:SelfType?) {
        let prevParent = self.parent
        self.setParent(newParent)
        prevParent?.removeChild(self)
        newParent?.addChild(self)
        newParent?.root.rebuildQuickMap()
    }
    
    private func _detachAll(recursivelyDowntree:Bool = false, recursionDepth:Int = 0) {
        let depth = self.depth
        let recursionDepth = recursivelyDowntree ? recursionDepth : 0 // ignore if not recursion
        guard recursionDepth <= Self.MAX_TREE_DEPTH && recursionDepth < Self.MAX_TREE_DEPTH else {
            dlog?.note("\(self).detachAll(recursivelyDowntree:\(recursivelyDowntree)) recursion depth exceeded MAX_TREE_DEPTH \(Self.MAX_TREE_DEPTH)")
            return
        }
        
        dlog?.info("   ".repeated(times: 2) + "\(self).detachAll(recursivelyDowntree:\(recursivelyDowntree))")
        
        if recursivelyDowntree {
            let children = self.allChildrenByDepth // recoursive call, does not include self.
            let maxDepth = children.keys.max() ?? 0
            for invertDepth in 0...maxDepth {
                let depth = maxDepth - invertDepth
                let childrenAtDepth = children[depth] ?? []
                for child in childrenAtDepth {
                    child._detachAll(recursivelyDowntree: false, recursionDepth:recursionDepth + 1)
                }
            }
            dlog?.info("detachAll(recursivelyDowntree) resulted in root: \((Self.rootNodes?.ids ?? []).descriptions().descriptionsJoined)")
        }
        
        // Handle self
        let prevParent = self.parent
        self.setParent(nil)
        self.removeChildren(self.children)
        self.unregisterFromQuickMap()
        if depth == 0 {
            prevParent?.rebuildQuickMap()
        }
    }
    
    func detachAll(recursivelyDowntree:Bool = false) {
        return _detachAll(recursivelyDowntree: recursivelyDowntree)
    }
    
    func debgValidateRelationship(parent:MNTreeNode, children: [MNTreeNode]) {
        guard MNUtils.debug.IS_DEBUG else {
            return
        }
        for child in children {
            if child.parent != parent {
                dlog?.warning("debugValidateChild \(child.id) parent is not \(parent.id)!")
            }
            if !parent.children.contains(elementEqualTo: child) {
                dlog?.warning("debugValidateChild \(child.id) parent is not \(self.id)!")
            }
        }
    }
    
    // MARK: Iterations / recursions
    // Basic recursion functions
    private func _recourseChildren<ResultType : Any>(_ block: (_ node:SelfType,_ depth:Int)->MNResumeStopTuple<ResultType>,
                                            includeSelf:Bool = false,
                                            recursionType:MNTreeNodeRecursionType,
                                            recursionDepth:Int, nodeDepth:Int)->MNResumeStopTuple<[ResultType]>  {
        
        guard recursionDepth <= Self.MAX_TREE_DEPTH && recursionDepth < Self.MAX_TREE_DEPTH else {
            dlog?.note("\(Self.self) _recourseChildren \(recursionType.description) recursion depth exceeded MAX_TREE_DEPTH \(Self.MAX_TREE_DEPTH)")
            return MNResumeStopTuple.stopEmpty
        }
        var result : [ResultType] = []
        
        // Add starting node or depth-first children
        if (recursionDepth == 0 && includeSelf) || ((recursionDepth > 0 || includeSelf) && recursionType == .depthFirst) {
            let rsTuple = block(self, nodeDepth)
            if let value = rsTuple.value { result.append(value) }
            
            // When user of this function decided to generically return the result of a MNResumeStopEnum (and does not know it's wrapped in a MNResumeStopTuple), we treat it as an instrution regarding the recursion:
            if rsTuple.valueType == MNResumeStopEnum.self, let valueInstruction = value as? MNResumeStopEnum,
                valueInstruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
            
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        // Add breadth-first children
        if recursionType == .breadthFirst {
            // We get the children's results before recoursing to next level
            debgValidateRelationship(parent:self, children :children)
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
        debgValidateRelationship(parent:self, children:children)
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
    
    private func _recourseParents<ResultType : Any>(_ block: (_ node:SelfType,_ depth:Int)->MNResumeStopTuple<ResultType>, includeSelf:Bool = false, recursionDepth:Int, nodeDepth:Int)->MNResumeStopTuple<[ResultType]> {
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
            
            // When user of this function decided to generically return the result of a MNResumeStopEnum (and does not know it's wrapped in a MNResumeStopTuple), we treat it as an instrution regarding the recursion:
            if rsTuple.valueType == MNResumeStopEnum.self, let valueInstruction = value as? MNResumeStopEnum,
                valueInstruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
            
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        }
        
        if let parent = parent {
            let rsTuple = parent._recourseParents(block, includeSelf: false, recursionDepth: recursionDepth + 1, nodeDepth: nodeDepth - 1)
            if let val = rsTuple.value {
                result.append(contentsOf: val)
            }
            if rsTuple.instruction == .stop {
                return MNResumeStopTuple.stop(result)
            }
        } else {
            // Is Root
            debgValidateRelationship(parent :self, children: children)
        }
        
        return MNResumeStopTuple.resume(result)
    }
    
    @discardableResult
    func recourseChildrenDepthFirst<V : Any>(_ block: (_ node:SelfType, _ depth:Int)->V?,
                                             stopTest:((_ node:SelfType,_ depth:Int, _ result: V?)->Bool)? = nil,
                                             includeSelf:Bool = true)->[V] {
        let rsTuple = self._recourseChildren({ node, depth in
            var result = MNResumeStopTuple.resume(block(node, depth))
            if stopTest?(node, depth, result.value) == true {
                result.changeToStop()
            }
            return result
        }, includeSelf:includeSelf, recursionType: .depthFirst, recursionDepth: 0, nodeDepth: self.depth)
        
        // Log if stooped
        if dlog?.isVerboseActive == true && rsTuple.instrutionIsStop {
            dlog?.verbose(log: .note, "recourseChildrenWidthFirst for \(self) was STOPPED!")
        }
        return rsTuple.value ?? []
    }
    
    @discardableResult
    public func recourseChildrenBreadthFirst<V : Any>(_ block:(_ node:SelfType, _ depth:Int)->V?,
                                             stopTest:((_ node:SelfType,_ depth:Int, _ result:V?)->Bool)? = nil,
                                               includeSelf:Bool = true)->[V] {
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
    public func recourseChildren<V : Any>(_ block:(_ node:SelfType, _ depth:Int)->V?,
                                   method: MNTreeNodeRecursionType,
                                   stopTest:((_ node:SelfType,_ depth:Int, _ result:V?)->Bool)? = nil,
                                   includeSelf:Bool = true)->[V] {
        switch method {
        case .depthFirst:   return self.recourseChildrenDepthFirst(block, stopTest: stopTest, includeSelf: includeSelf)
        case .breadthFirst: return self.recourseChildrenBreadthFirst(block, stopTest: stopTest, includeSelf: includeSelf)
        }
    }
    
    @discardableResult
    public func recourseParents<V : Any>(_ block:(_ node:SelfType, _ depth:Int)->V?,
                                  stopTest:((_ node:SelfType,_ depth:Int, _ result:V?)->Bool)? = nil,
                                  includeSelf:Bool = true)->[V] {
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
    public var idPath : [IDType] {
        return self.recourseParents({ node, depth in
            return node.id
        }, includeSelf: true)
    }
    
    // Re
    public func idPathStrings() -> [String] {
        return self.recourseParents({ node, depth in
            
            // Is this needed? we have  where IDType : CustomStringConvertible {
            if let anid = node.id as? CustomDebugStringConvertible {
                return anid.debugDescription
            }
            return "\(node.id)"
        }, includeSelf: true)
    }
    
    public func idPathStrings() -> [String] where IDType : CustomStringConvertible {
        return self.recourseParents({ node, depth in
            return node.id.description
        }, includeSelf: true)
    }

    public func allChildren(includeSelf: Bool) -> [MNTreeNode<ValueType, IDType>] {
        return self.recourseChildrenDepthFirst({ node, depth in
            return node
        }, includeSelf: includeSelf)
    }
    
    /// Return the count of all the child nodes down thre tree (optional: including self)
    /// - Parameter includeSelf: should include self in the count
    /// - Returns: amount (count) of all children down the tree, if specified is incremented by 1 (for self)
    public func allChildrenCount(includeSelf:Bool) -> Int {
        var result = 0
        self.iterateChildrenDowntree({(node, depth) in
            result += 1
            return .resume
        }, includeSelf: true, method: .depthFirst)
        return result
    }
    
    public func allParents(includeSelf: Bool) -> [MNTreeNode<ValueType, IDType>] {
        return self.recourseParents({ node, depth in
            return node
        }, includeSelf: includeSelf)
    }

    public func allChildrenByDepth(includeSelf: Bool) -> [Int : [MNTreeNode<ValueType, IDType>]] {
        guard self.children.count > 0 else {
            return [:]
        }
        
        let results : [(Int, SelfType)] = self.recourseChildrenDepthFirst({ node, depth in
            if includeSelf || node != self {
                return (depth, node)
            } else if node == self && !includeSelf {
                dlog?.note("recourseChildrenDepthFirst has a problem! (visited self while includeSelf is false!)")
            }
            return nil
        }, includeSelf: includeSelf)
        
        let result = results.toDictionaryOfArrays { elem in
            return elem.0
        } arrayItemForItem: { elem in
            return elem.1
        }
        
        return result
    }
    
    public func allParentsByDepth(includeSelf: Bool) -> [Int : MNTreeNode<ValueType, IDType>] {
        return self.allParents(includeSelf: includeSelf).toDictionary { element in
            element.depth
        } itemForItem: { key, element in
            element
        }
    }

    // Common recursion functions
    public func filterChildrenDowntree(where block:(_ node:SelfType, _ depth:Int)->Bool = {(_,_) in false}, includeSelf:Bool, method:MNTreeNodeRecursionType)->[SelfType] {
        return self.recourseChildren({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, method: method, stopTest: nil, includeSelf: includeSelf)
    }
    
    public func firstChildDowntree(where block:(_ node:SelfType, _ depth:Int)->Bool = {(_,_) in false}, includeSelf:Bool, method:MNTreeNodeRecursionType)->SelfType? {
        return self.recourseChildren({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, method: method, stopTest: nil, includeSelf: includeSelf).first
    }
    
    public func filterParents(where block:(_ node:SelfType, _ depth:Int)->Bool = {(_,_) in false}, includeSelf:Bool)->[SelfType] {
        return self.recourseParents({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, stopTest: nil, includeSelf: includeSelf)
    }
    
    public func firstParent(where block:(_ node:SelfType, _ depth:Int)->Bool = {(_,_) in false}, includeSelf:Bool)->SelfType? {
        return self.recourseParents({ node, depth in
            if block(node, depth) {
                return node
            }
            return nil
        }, stopTest: nil, includeSelf: includeSelf).first
    }
    
    @discardableResult
    public func iterateChildrenDowntree(_ block: (MNTreeNode<ValueType, IDType>, Int) -> MNResumeStopEnum = {(_, _) in .resume},
                                        includeSelf: Bool,
                                        method: MNTreeNodeRecursionType) -> MNResumeStopEnum {
        // NOTE: SEE in recourseChildren's implementation what happens when the completion block result type is MNResumeStopEnum OR MNResumeStopTuple
        let allResults = self.recourseChildren(block, method: method, stopTest: nil,
        includeSelf: includeSelf)
        return allResults.contains(.stop) ? .stop : .resume
    }
    
    @discardableResult
    public func iterateParentNodes(_ block: (MNTreeNode<ValueType, IDType>, Int) -> MNResumeStopEnum  = {(_, _) in .resume},
                                   includeSelf: Bool) -> MNResumeStopEnum {
        // NOTE: SEE in recourseParents's implementation what happens when the completion block result type is MNResumeStopEnum OR MNResumeStopTuple
        
        let allResults = self.recourseParents(block,stopTest: nil,
        includeSelf: includeSelf)
        return allResults.contains(.stop) ? .stop : .resume
    }
    
    public func isParentOf(node anode:SelfType)->Bool {
        guard anode != self else {
            return false
        }
        
        let result = self.firstChildDowntree(where: { achild, depth in
            achild == anode
        }, includeSelf: false, method: .depthFirst) != nil
        
        if MNUtils.debug.IS_DEBUG && result == false {
            if anode.isParentOf(node: self) {
                dlog?.note("isParentOf(node: \(anode)) is a child of \(self)! Maybe you wanted to ask isParentOf(node:) with reversed param / caller?")
            }
        }
        
        return result
    }
    
    /// Determine if this node is a child or descendant of the provided node
    /// - Parameter anode: node to test for ancestry
    /// - Returns: true if this node is a descendant of the provided node
    public func isChildOf(node anode:SelfType)->Bool {
        guard anode != self else {
            return false
        }
        
        let result = self.firstParent(where: { aparent, depth in
            aparent == anode
        }, includeSelf: false) != nil
        
        if MNUtils.debug.IS_DEBUG && result == false {
            // If this a case or reversed param / caller?
            if anode.root.firstParent(where: { aparent, depth in
                aparent == self
            }, includeSelf: false) != nil {
                dlog?.note("isChildOf(node: \(anode)) is a child of \(self)! Maybe you wanted to ask isChildOf(node:) with reversed param / caller?")
            }
        }
        
        return result
    }
    
    /// Determine if this node is a child or descendant of the provided node
    /// - Parameter anode: node to test for ancestry
    /// - Returns: true if this node is a descendant of the provided node
    public func isChildOf(node anode:any MNTreeNodeProtocol)->Bool {
        guard let mnnode = anode as? SelfType else {
            return false
        }
        
        return self.isChildOf(node: mnnode)
    }
    
    /// Determine if this node is a child or descendant of ANY of the provided nodes
    /// - Parameter nodes: nodes to test for ancestry
    /// - Returns: true if this node is a descendant of at least one of the provided nodes
    public func isChildOf(anyIn nodes : [SelfType])->Bool {
        for anode in nodes {
            if self.isChildOf(node: anode) {
                return true
            }
        }
        return false
    }
    
    /// Determine if this node is a child or descendant of ANY of the provided nodes
    /// - Parameter nodes: nodes to test for ancestry
    /// - Returns: true if this node is a descendant of at least one of the provided nodes
    public func isChildOf(anyIn nodes : [any MNTreeNodeProtocol])->Bool {
        for anode in nodes {
            if self.isChildOf(node: anode) {
                return true
            }
        }
        return false
    }
    
}

extension MNTreeNode where IDType : LosslessStringConvertible {
    convenience init?(id: IDType, value: ValueType?, parentIDString: String) {
        
        guard let parentId = IDType(parentIDString) else {
            preconditionFailure("\(Self.self).init(init(id:value:parentIDString:) could not create an \(IDType.self) instance from:(parentIDString) for value: \(value.descOrNil)")
        }
        
        guard let existingParent = Self.quickFetch(byId: parentId) else {
            Self.addToReconstrutionList(id: id, value: value, parentId: parentId, depth: .unknown) // depth is tentatively one
            return nil
        }
        
        self.init(id: id, value: value, parent: existingParent)
        dlog?.verbose(log:.success, "\(Self.self).init(id: \(id), value: \(value.descOrNil) parentIDString: \(parentIDString) (parent already exited)")
    }
}

extension MNTreeNode where IDType : Hashable {
    
    var childrenById : [IDType:SelfType] {
        return self.children.toDictionary { $0.id as IDType }
    }
    
    var allChildrenById : [IDType:SelfType] {
        return self.allChildren.toDictionary { $0.id as IDType }
    }
    
    var allParentsById : [IDType:SelfType] {
        return self.allParents.toDictionary { $0.id as IDType }
    }
    
}

// ======================== Sequence extension =============================

// MARK: Sequence extension
extension Sequence where Element : MNTreeNodeProtocol { // , Element.IDType : Equatable
    
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

extension Sequence where Element : MNTreeNodeProtocol, Element.IDType : Any {
    var idDescriptions : [String] {
        return self.map { elem in
            return "\(elem.id)"
        }
    }
}


extension Sequence where Element == MNTreeNode<AnyHashable, AnyHashable> {
    
    var nodesById : [Element.IDType:Element] {
        return self.toDictionary { element in
            element.id
        }
    }
    
}

// Type 'any MNTreeNodeProtocol' cannot conform to 'Hashable'

extension Sequence where Element : MNTreeNodeProtocol {
    
    /// Returns the same array, but sorted so that elements with less children are first, or later
    /// - Parameter byChildrenAscending: will sort from nodes with lowest number or children to height, when false, will return the reverse.
    /// - Returns: array of MNTreeNodes sorted by amount of children for each node in the array.
    @inlinable public func sorted(byChildrenCountAscending isAscending:Bool) -> [Element] {
        return self.sorted { chld1, chld2 in
            return isAscending ?
                (chld1.children.count < chld2.children.count) :
                (chld1.children.count > chld2.children.count)
        }
    }
    
    @inlinable public func sorted(byIDsAscending isAscending:Bool) -> [Element] where Element.IDType : Comparable {
        return self.sorted { chld1, chld2 in
            return isAscending ?
                (chld1.id < chld2.id) :
                (chld1.id > chld2.id)
        }
    }
    
    @inlinable public func sorted(byValuessAscending isAscending:Bool) -> [Element] where Element.ValueType : Comparable {
        return self.sorted { chld1, chld2 in
            if let val1 = chld1.value {
                if let val2 = chld2.value {
                    return isAscending ?
                        (val1 < val2) :
                        (val1 > val2)
                } else {
                    return false
                }
            } else {
                return true
            }
        }
    }
    
}
