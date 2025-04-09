//
//  MNTreeNode+Config.swift
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

fileprivate let dlog : Logger? = Logger(label: "MNTreeNode+Config") // ?.setting(verbose: false, testing: IS_TESTING)

// MARK: Types
public class MNTreeConfig : CustomStringConvertible {
    
    static let nodeKeysPrefix = MNUtils.debug.IS_DEBUG ? "" : "_" + String.SECTION_SIGN // "_§" this allows to distinguish in the JSON between node Value attributes and tree structure attributes.
    
    // MARK: Types
    enum WhenDetachedNamingStrategy : String, Codable, CaseIterable {
        // Assuming origianal tree was "MyName"
        case copyAndEnumerate // "MyTree.001"
        case copyAndUUID // "MyTree.550e8400-e29b-41d4-a716-446655440000"
        case useNewRootId // "MyNodeId.detachedFrom.MyTree"
        case selfUUID // "550e8400-e29b-41d4-a716-446655440000"
    }
    
    // MARK: Const
    static var DELIMITER : String { "." }
    static var DETACHED_KEY : String { "detachedFrom" }
    static var ENUMERATED_NR_OF_DIGITS = 3
    
    // MARK: Static
    // MARK: Properties / members
    private var enumerationCounter : Int = 0
    private(set) var uuid : UUID
    private(set) var treeName : String?
    private(set) var treeKey : String
    
    
    /// Determines is a tree of nodes is saved "flat" in the encoded version and reconstructed using the parentId for each node, or saved as a tree structure, which inherantly contains the parent relations.
    var isEncodeFlat : Bool = true
    
    /// Encode the starting/top node of the tree being encoded with additional info and stats relating to sums of all nodes downtree.
    ///
    /// NOTE: The starting / top node is not neccessarily the root of the whole tree!
    var isEncodeWithRootInfo : Bool = false // "rootInfo" terminology is the same as "treeInfo"
    
    /// Encode each node with a "node info" stats and info portion
    var isEncodeWithNodeInfo : Bool = false
    
    /// When a subnode is detached from the tree, determine the name of the new tree created:
    var whenDetachedNamingStrategy : WhenDetachedNamingStrategy = .copyAndEnumerate
    
    /// Perofrms all sorts of test when changing the tree to prevent recursion loop (cyclic references etc) or duplicate nodes in one tree
    /// NOTE: This may prove to be CPU intensive, since on every addition and removal to the tree, some checks will use recursive methods.
    var isValidatesPossibleRecursiveIssues : Bool = MNUtils.debug.IS_DEBUG
    
    /// When a node is added to the tree, or tree structure changes, children array for each node is sorted according to this method
    var sortMethod : MNTreeNodeSorting = (.byChildrenCount, true)

    private(set) weak var rootNode : (any MNTreeNodeProtocol)? {
        didSet {
            if self.rootNode == nil {
                dlog?.todo("\(self) rootNode was killed - handle this!")
            }
            if self.rootNode?.isRoot == false {
                dlog?.todo("\(self) rootNode id: \(self.rootNode!.id) is not a root - handle this!")
                //TODO: should we do: self.rootNode = self.rootNode.root ?
            }
        }
    }
    
    // MARK : CustomStringConvertible
    public var description : String {
        if let treeName = treeName {
            return "<MNTreeConfig." + treeName + " MNTree.root.\((rootNode?.id).descOrNil) >"
        } else {
            // No tree name
            return "<MNTreeConfig. UUID:\(self.uuid) MNTree.root.\((rootNode?.id).descOrNil) >"
        }
        
    }
        
    // MARK: Private
    private func rootNodeName () -> String?  {
        if let root = self.rootNode {
            if root.isRoot == false {
                dlog?.notice("\(self) rootNodeName for root node: \( "\(root)" ) where rootNode is NOT a root!")
            }
            return "\(root.id)"
        }
        
        return nil
    }
    
    private func cleanTreeName()->String {
        let baseName = self.treeName ?? (self.rootNode != nil ? "MNTree.root.\(rootNode!.id)" : self.uuid.uuidString)
        var comps = baseName.components(separatedBy: Self.DELIMITER)
        
        // REMOVE "detached from" mid key?
        if false && comps.count > 2 {
            let mid = comps[comps.count - 2]
            if mid == Self.DETACHED_KEY {
                comps.remove(at: comps.count - 2)
            }
        }
        
        if let last = comps.last {
            if UUID(uuidString: last) != nil ||  // last comp was UUID
                last.isAllDigits && last.count >= Self.ENUMERATED_NR_OF_DIGITS { // last comp was Int "001" etc..
                comps.removeLast()
            }
            
        }
        return comps.joined(separator: Self.DELIMITER)
    }
    
    // MARK: Lifecycle
    init(name:String?, rootNode: any MNTreeNodeProtocol,
         encodeFlat : Bool = true,
         encodeWithRootInfo : Bool = false,
         encodeWithNodeInfo : Bool = false)
    {
        self.uuid = UUID()
        self.rootNode = rootNode
        let delim = Self.DELIMITER
        self.treeName = name ?? "MNTree.root" + delim + "\(rootNode.id)"
        self.treeKey = "\(rootNode.TREE_NODE_TYPE_KEY)" + delim + uuid.uuidString + "root"
        
        // After all props were inited:
        self.treeKey = self.treeKey + delim + self.rootNodeName().descOrNil
    }
    
    // MARK: Public
    func renameTree(_ newName:String) {
        treeName = newName
    }
    
    private func treeNameForDetachedTree(newRootNode:any MNTreeNodeProtocol, newUUID:UUID)->String {
        var result = cleanTreeName()
        let delim = Self.DELIMITER
        
        switch whenDetachedNamingStrategy {
        case .copyAndEnumerate: // "MyTree.001"
            self.enumerationCounter += 1
            result = result + delim + self.enumerationCounter.asString(minDigits: Self.ENUMERATED_NR_OF_DIGITS)
            
        case .copyAndUUID: // "MyTree.550e8400-e29b-41d4-a716-446655440000"
            result = result + delim + self.uuid.uuidString
            
        case .useNewRootId: // "MyNodeId.detachedFrom.MyTree"
            // var DETACHED_KEY : String { "detachedFrom" }
            result = result + delim + Self.DETACHED_KEY + "." + (self.rootNodeName() ?? self.uuid.uuidString)
            
        case .selfUUID: // "550e8400-e29b-41d4-a716-446655440000"
            result = "\(newUUID.uuidString)"
        }
        
        return result
    }
    
    private func copy() throws -> MNTreeConfig {
        guard let root = self.rootNode else {
            throw MNError(code: .misc_bad_input, reason: "\(self).copy() where rootNode is nil!")
        }
        
        let copy = MNTreeConfig(name: self.treeName,
                                rootNode: root,
                                encodeFlat: self.isEncodeFlat,
                                encodeWithRootInfo: self.isEncodeWithRootInfo,
                                encodeWithNodeInfo: self.isEncodeWithNodeInfo)
        copy.whenDetachedNamingStrategy = self.whenDetachedNamingStrategy
        copy.treeKey = self.treeKey
        copy.treeName = self.treeName
        copy.enumerationCounter = self.enumerationCounter + 1
        return copy
    }
    
    func detachCopy<T:MNTreeNodeProtocol>(newRoot:T) throws ->MNTreeConfig {
        let copy = try self.copy()
        copy.rootNode = newRoot
        copy.treeName = self.treeNameForDetachedTree(newRootNode: newRoot, newUUID:copy.uuid)
        copy.treeKey = newRoot.TREE_NODE_TYPE_KEY + Self.DELIMITER + copy.enumerationCounter.toString(minDigits: Self.ENUMERATED_NR_OF_DIGITS)
        
        (newRoot as? T.SelfType)?.setTreeConfig(copy)
        return copy
    }
}

fileprivate var _MNTreeNodeConfigs : [String:MNTreeConfig] = [:]

extension MNTreeNode {
    
    // MARK: get / set
    func getTreeConfig() throws ->MNTreeConfig {
        guard MNExec.isMain else {
            throw MNError(code: .misc_failed_reading, reason: "MNTreeConfig must be called on main thread only!")
        }
        
        if let config = _MNTreeNodeConfigs[self.TREE_NODE_TYPE_KEY] {
            return config
        }
        let config = MNTreeConfig(name: nil, rootNode: self.root)
        _MNTreeNodeConfigs[self.TREE_NODE_TYPE_KEY] = config
        return config
    }
    
    func setTreeConfig(_ config:MNTreeConfig) {
        guard DispatchQueue.isMainQueue else {
            MNExec.exec(afterDelay: 0) { [self, config] in
                self.setTreeConfig(config)
            }
            return
        }
        
        // Set value:
        _MNTreeNodeConfigs[self.TREE_NODE_TYPE_KEY] = config
    }
    
    public var config : MNTreeConfig {
        get {
            do {
                return try getTreeConfig()
            } catch let error {
                dlog?.critical("cannot .get MNTreeConfig for \(self). error: \(error)")
                preconditionFailure("\(self) cannot .get MNTreeConfig for \(self). Unknown error")
            }
        }
        set {
            setTreeConfig(newValue)
        }
    }
    
}
