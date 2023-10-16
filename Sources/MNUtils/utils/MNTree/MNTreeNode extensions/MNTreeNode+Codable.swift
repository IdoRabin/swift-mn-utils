//
//  MNTreeNode+Codable.swift
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

fileprivate let dlogRegistry : DSLogger? = DLog.forClass("MNTreeNode+Codable |reg|")?.setting(verbose: false, testing: IS_TESTING)
fileprivate let dlogDecode : DSLogger? = DLog.forClass("MNTreeNode+Codable |dec|")?.setting(verbose: false, testing: IS_TESTING)
fileprivate let dlogEncode : DSLogger? = DLog.forClass("MNTreeNode+Codable |enc|")?.setting(verbose: true, testing: IS_TESTING)

extension MNTreeNode : Codable where IDType : Codable, ValueType : Codable {
    
    // MARK: Types
    // MARK: Coding keys
    
    // MARK: Const
    // MARK: Static
    
    // MARK: Properties / members
    // MARK: Private
    
    // TODO:
    private func encodeSingle(keyed container: inout KeyedEncodingContainer<CodingKeys>, node:SelfType, isFlat:Bool) throws {
        
        UnknownMNTreeDecodingObj.registerNodeType(node: self)
        
        try container.encode(node.id, forKey: .id)
        try container.encodeIfPresent(node.value, forKey: .value)
        try container.encodeIfPresent(node.parent?.id, forKey: .parentId)
        
        if isFlat && node.children.count > 0 {
            // Array of children ids
            try container.encode(node.children.ids, forKey: .childrenIds)
        }
        
        if self.isRoot && self.config.isEncodeWithRootInfo {
            // Root info
            // "rootInfo" terminology is the same as "treeInfo"
            var treeInfoContainer = container.nestedContainer(keyedBy: MNTreeNode.RootInfoCodingKeys.self, forKey: MNTreeNode.CodingKeys.treeInfo)
            
            // RootInfoCodingKeys
            let allChilds = self.allChildren
            try treeInfoContainer.encode("\(IDType.self)", forKey: .idType)
            try treeInfoContainer.encode("\(ValueType.self)", forKey: .valueType)
            try treeInfoContainer.encode(allChilds.count, forKey: .totalItemsCount)
        }
        
        if self.config.isEncodeWithNodeInfo {
            var infoContainer = container.nestedContainer(keyedBy: MNTreeNode.NodeInfoCodingKeys.self, forKey: MNTreeNode.CodingKeys.nodeInfo)
            try infoContainer.encode(node.depth, forKey: .nodeDepth)
            try infoContainer.encode(node.hashValue, forKey: .nodeHash)
            try infoContainer.encode(node.nodeType, forKey: .nodeRoleInTree) // leaf / node / root
        }
    }
    
    private func encodeSingle(unkeyed container: inout UnkeyedEncodingContainer, node:SelfType, isFlat:Bool) throws {
        
        var single = container.nestedContainer(keyedBy: MNTreeNode.CodingKeys.self)
        try self.encodeSingle(keyed: &single, node: node, isFlat:isFlat)
    }
    
    private func encodeFlat(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MNTreeNode.CodingKeys.self)
        try container.encode(Self.TREE_NODE_TYPE_KEY, forKey: .treeNodeTypeKey)
        
        var keyedContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .flatTree)
        // Encode self in the tree:
        try self.encodeSingle(keyed: &keyedContainer, node: self, isFlat: true)

        if self.children.count > 0 {
            let allNodesByDepth = self.allChildrenByDepth(includeSelf: false)
            var unkeyedContainer = keyedContainer.nestedUnkeyedContainer(forKey: .children)
            let maxDepth = allNodesByDepth.keys.max() ?? 0
            
            // Encode all children by depth as members of the flat array:
            var flatNodes : [SelfType] = [] // does not include self!
            for childDepth in 0...maxDepth {
                if var childrenAtDepth = allNodesByDepth[childDepth], childrenAtDepth.count > 0 {
                    dlogEncode?.verbose("  encodeFlat: childrenAtDepth: \(childDepth) are \(childrenAtDepth.ids)")
                    // Encode children by order of depth:
                    if MNUtils.debug.IS_DEBUG {
                        childrenAtDepth = childrenAtDepth.sorted(byChildrenCountAscending: true)
                    }
                    for child in childrenAtDepth {
                        if !flatNodes.contains(elementEqualTo: child) { // JIC
                            flatNodes.append(child)
                        }
                    }
                }
            }
            
            // Encode child nodes as flat array:
            for node in flatNodes {
                try self.encodeSingle(unkeyed: &unkeyedContainer, node: node, isFlat: true)
            }
        }
    }
    
    private func encodeTreeNode(to encoder: Encoder, nodesContainer : inout UnkeyedEncodingContainer) throws {
        var container = nodesContainer.nestedContainer(keyedBy: MNTreeNode.CodingKeys.self)
        // Encode self in the tree:
        try self.encodeSingle(keyed: &container, node: self, isFlat: false)
        
        if self.children.count > 0 {
            var childrenContainer = container.nestedUnkeyedContainer(forKey: .children)// .nestedContainer(keyedBy: MNTreeNode.CodingKeys.self, forKey: .children)
            
            var childs = self.children
            if MNUtils.debug.IS_DEBUG {
                childs = childs.sorted(byChildrenCountAscending: true)
            }
            for child in childs {
                // Encode child as a member of the Tree:
                try child.encodeTreeNode(to: encoder, nodesContainer:&childrenContainer)
            }
        }
    }
    
    private func encodeTree(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: MNTreeNode.CodingKeys.self)
        try container.encode("\(Self.TREE_NODE_TYPE_KEY)", forKey: .treeNodeTypeKey)
        
        var treeContainer = container.nestedContainer(keyedBy: MNTreeNode.CodingKeys.self, forKey: .fullTree)

        // Encode self in the tree:
        try self.encodeSingle(keyed: &treeContainer, node: self, isFlat: false)

        // Encode direct children
        if self.children.count > 0 {
            var childrenContainer = treeContainer.nestedUnkeyedContainer(forKey: .children)// .nestedContainer(keyedBy: MNTreeNode.CodingKeys.self, forKey: .children)

            var childs = self.children
            if MNUtils.debug.IS_DEBUG {
                childs = childs.sorted(byChildrenCountAscending: true)
            }
            
            for child in childs {
                // Encode child as a member of the Tree:
                try child.encodeTreeNode(to: encoder, nodesContainer:&childrenContainer)
            }
        }
    }
    
    // MARK: Lifecycle
    public func encode(to encoder: Encoder) throws {
        UnknownMNTreeDecodingObj.registerNodeType(node: self)
        
        // Determine encode structure / method:
        dlogEncode?.verbose("\(Self.self) \"\(id)\".encode(to encoder) isFlat: \(self.config.isEncodeFlat ? "flat" : "tree")")
        if self.config.isEncodeFlat {
            try self.encodeFlat(to: encoder)
        } else {
            try self.encodeTree(to: encoder)
        }
    }
}

extension Sequence where Element : MNTreeNodeProtocol, Element : Codable, Element.IDType : Codable, Element.ValueType : Codable {
    
    public var asMNTreeNodeCollection : MNTreeNodeCollection {
        let selfCasted = self as! [any MNTreeNodeProtocol]
        return MNTreeNodeCollection(nodes: selfCasted)
    }
}


class UnknownMNTreeDecodingObj : Codable {
    typealias TypeRecord = (any MNTreeNodeProtocol.Type, Any.Type, Any.Type)
    fileprivate static var nodeTypes : [String:TypeRecord] = [:]
    var key : String
    @SkipEncode var instance : (any MNTreeNodeProtocol)? = nil
    
    static func registerNodeType<ValueType, IDType>(key:String, node:MNTreeNode<ValueType, IDType>) {
        if !nodeTypes.hasKey(key) {
            let nodeType = type(of:node as (any MNTreeNodeProtocol))
            nodeTypes[key] = TypeRecord(nodeType, ValueType.self, IDType.self)
            dlogRegistry?.verbose(log: .success, "registerNodeType: \(key) : \(nodeType) | \(ValueType.self) | \(IDType.self)")
        }
    }
    
    public static func registerNodeType<ValueType, IDType>(node:MNTreeNode<ValueType, IDType>) {
        self.registerNodeType(key: node.TREE_NODE_TYPE_KEY, node: node)
    }
    
    public static func getNodeTypeRecord(byKey key:String)->TypeRecord? {
        if let record = nodeTypes[key] {
            dlogRegistry?.verbose(">> getNodeType byKey:\(key) -> \(record)")
            return record
        }
        return nil
    }
    
    public static func getNodeType(byKey key:String)->MNTreeNode<AnyHashable, AnyHashable>.Type? {
        if let record = nodeTypes[key] {
            dlogRegistry?.verbose(">> getNodeType byKey: \(key) -> \(record)")
            return nil
        }
        return nil
    }
    
    required init(from decoder: Decoder) throws {
        
        dlogDecode?.verbose("UnknownMNTreeDecodingObj init(from decoder:)")
        let container = try decoder.container(keyedBy: MNTreeNode<String, String>.CodingKeys.self)
        var codableType : Codable.Type? = nil
        guard let key = try container.decodeIfPresent(String.self, forKey: .treeNodeTypeKey) else {
            throw MNError(code: .misc_failed_decoding, reason: "\(Self.self) failed finding tree type key")
        }
        self.key = key
        
        //dlog?.info(">>  UnknownMNTreeDecodingObj key: \(self.key)")
        if let cache = MNTreeNodeMgr.shared.cacheFor(nodeTypeString: self.key) {
            dlogDecode?.verbose(log:.success, "UnknownMNTreeDecodingObj found cache: \(cache)")
        } else if let type = StringAnyDictionary.getType(typeName: key) {
            dlogDecode?.verbose(log:.success, "UnknownMNTreeDecodingObj found cache for key: \(self.key) type: \(type)")
        } else if let record = Self.getNodeTypeRecord(byKey: self.key){
            codableType = record.0 as? Codable.Type
            dlogDecode?.verbose(log:.success, "UnknownMNTreeDecodingObj found type: \(record) : codableType \(codableType.descOrNil)")
        } else {
            dlogDecode?.fail(">> UnknownMNTreeDecodingObj Failed finding type for key: \(self.key)")
        }
        
        // Use the correct type:
        if let codableType = codableType {
            do {
                // Determine tree type:
                // search for "Actual basic implementation init(from decoder) for MNTreeNode"
                if let instance = (try codableType.init(from: decoder)) as? any MNTreeNodeProtocol {
                    dlogDecode?.verbose("UnknownMNTreeDecodingObj Decoded: \(instance) : \(type(of: instance)) | as \(codableType) recreated exact type: \(instance.TREE_NODE_TYPE_KEY == self.key)")
                    self.instance = instance
                } else {
                    dlogDecode?.fail("UnknownMNTreeDecodingObj Failed Decoding: \(codableType) - returned nil")
                }
            } catch let error {
                dlogDecode?.fail("UnknownMNTreeDecodingObj Failed Decoding: \(codableType) - error: \(error.description)")
                throw error
            }
        }
        
        // JIC
        if self.instance == nil {
            throw MNError(code: .misc_failed_decoding, reason: "\(Self.self) failed finding decoding for \(codableType.descOrNil)")
        }
    }
    
}
