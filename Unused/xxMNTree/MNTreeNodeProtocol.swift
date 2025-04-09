//
//  MNTreeNodeProtocol.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeProtocol") // ?.setting(verbose: false)

public protocol MNTreeNodeBaseProtocol<ValueType, IDType> : AnyObject, Equatable, Hashable {
    associatedtype IDType : Hashable
    associatedtype ValueType : Hashable // Needed for some caching operations
    associatedtype SelfType : MNTreeNode<ValueType, IDType>
    
    var value : ValueType? { get }
    var id : IDType { get }
    var children : [SelfType]  { get }
    var parent : SelfType? { get }
    static var TREE_NODE_TYPE_KEY : String { get }
    
    var isRoot : Bool { get }
    var isLeaf : Bool { get }
    var isNode : Bool { get }
    var root :  SelfType { get }
}

public protocol MNTreeNodeProtocol<ValueType, IDType> : MNTreeNodeBaseProtocol, Equatable, Hashable {
    // Tree info:
    var idPath : [IDType] { get }
    
    /// List all children of this node (recursive downtree)
    /// NOTE: does NOT include self!
    var allChildren : [SelfType] { get }

    /// Return the count (amount) of all children down the tree (not including self)
    var allChildrenCount : Int { get }
    
    /// List all parents of this node (recursive uptree)
    /// NOTE: does NOT include self!
    var allParents : [SelfType] { get }
    
    /// List all children of this node (recursive downtree) as a dictionary of all nodes for a given depth by the key of their depth. Dictionary of arrays.
    ///  One may assume the dictionary int keys will run from self.depth to the deepest node's depth
    /// NOTE: does NOT include self!
    var allChildrenByDepth : [Int:[SelfType]]  { get }
    
    /// List all parents of this node (recursive uptree) as a dictionary of each parent and its depth in the tree.
    ///  One may assume the dictionary int keys will run from 0 to self.depth
    /// NOTE: does NOT include self!
    var allParentsByDepth : [Int:SelfType] { get }
    
    /// Get the static configauration relating to this node tree of THIS tree type.
    /// NOTE: theere are differnt setings for each ValueType, IDType tuple - see TREE_NODE_TYPE_KEY, or config.treeKey
    var config : MNTreeConfig { get set }
    
    
    /// List the ids of all parents and self by order from the root node
    /// NOTE: result.first should be the tree root. result.last should be self.
    /// - Returns: array of all parent ids by order
    func idPathStrings() -> [String]
    
    // Filter / recourse:
    
    @discardableResult
    func recourseChildren<V : Any>(_ block:(_ node:SelfType, _ depth:Int)->V?,
                                   method: MNTreeNodeRecursionType,
                                   stopTest:((_ node:SelfType,_ depth:Int, _ result:V?)->Bool)?,
                                   includeSelf:Bool)->[V]
    
    @discardableResult
    func recourseParents<V : Any>(_ block:(_ node:SelfType, _ depth:Int)->V?,
                                  stopTest:((_ node:SelfType,_ depth:Int, _ result:V?)->Bool)?,
                                  includeSelf:Bool)->[V]
    
    /// Filter all nodes down the tree (starting with this node) and filter them using a given test block
    /// - Parameters:
    ///   - block: block to filter the nodes: return true to include the node in the resulting array.
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    ///   - method: method of search - depth first or breadth (width) first.
    /// - Returns: array of all nodes down the three starting with this node (self) that passed the test. An empty result indicates no node matched the test block.
    func filterChildrenDowntree(where block:(_ node:SelfType, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->[SelfType]
        
    /// Iterate all children down the tree, with the option to stop the iteration mid-recursion
    /// - Parameters:
    ///   - block: block to handle each iteration / node in the tree. Return .stop to stop the iteration
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    ///   - method: method of search - depth first or breadth (width) first.
    /// - Returns:.stop when stopped mid-recursion, resume when all nodes were iterated
    @discardableResult
    func iterateChildrenDowntree(_ block:(_ node:SelfType, _ depth:Int)->MNResumeStopEnum, includeSelf:Bool, method:MNTreeNodeRecursionType)->MNResumeStopEnum
    
    /// Find the first node down thre tree (starting with this node) that match a given test block
    /// - Parameters:
    ///   - block: block to test the nodes: return true to stop the recursion and return the node as the result
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    ///   - method: method of search - depth first or breadth (width) first.
    /// - Returns: the first node matching the test block, or nil if no node in the tree matches the test block
    func firstChildDowntree(where block:(_ node:SelfType, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->SelfType?
    
    /// Filter all the nodes up the tree (starting with this node) and filter them using a given test block
    /// - Parameters:
    ///   - block: block to filter the nodes: return true to include the node in the resulting array
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    /// - Returns: array of all nodes up the three starting with this node (self) that passed the test. An empty result indicates no node matched the test block.
    func filterParents(where block:(_ node:SelfType, _ depth:Int)->Bool, includeSelf:Bool)->[SelfType]
    
    /// Find the first node up thre tree (starting with this node) that match a given test block
    /// - Parameters:
    ///   - block: block to test the nodes: return true to stop the recursion and return the node as the result
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    /// - Returns: the first node matching the test block, or nil if no node in the tree matches the test block
    func firstParent(where block:(_ node:SelfType, _ depth:Int)->Bool, includeSelf:Bool)->SelfType?
    
    /// Iterate all parents up the tree, with the option to stop the iteration mid-recursion
    /// - Parameters:
    ///   - block: block to handle each iteration / node in the tree. Return .stop to stop the iteration
    ///   - includeSelf: determines if self (the starting node) should be included in the search and possibly the result
    /// - Returns:.stop when stopped mid-recursion, resume when all nodes were iterated
    @discardableResult
    func iterateParentNodes(_ block:(_ node:SelfType, _ depth:Int)->MNResumeStopEnum, includeSelf:Bool)->MNResumeStopEnum
    
    /// Determine if this node is a child or descendant of the provided node
    /// - Parameter anode: node to test for ancestry
    /// - Returns: true if this node is a descendant of the provided node
    func isChildOf(node anode:SelfType)->Bool
    
    /// Determine if this node is a child or descendant of the provided node
    /// - Parameter anode: node to test for ancestry
    /// - Returns: true if this node is a descendant of the provided node
    func isChildOf(node anode:any MNTreeNodeProtocol)->Bool
    
    /// Determine if this node is a child or descendant of ANY of the provided nodes
    /// - Parameter nodes: nodes to test for ancestry
    /// - Returns: true if this node is a descendant of at least one of the provided nodes
    func isChildOf(anyIn nodes : [SelfType])->Bool
    
    /// Determine if this node is a child or descendant of ANY of the provided nodes
    /// - Parameter nodes: nodes to test for ancestry
    /// - Returns: true if this node is a descendant of at least one of the provided nodes
    func isChildOf(anyIn nodes : [any MNTreeNodeProtocol])->Bool
    
    
    /// Determine if this node is a parent or ancestor of the provided node.
    /// - Parameter anode: node to test for ancestry
    /// - Returns: true if this node is a parent (direct or indirect) of the provided node
    func isParentOf(node anode:SelfType)->Bool
    
    
    // == Convenience tree info
    
    /// List all children of this node (recursive downtree)
    /// - Parameter includeSelf: determines if the recusion and result include self( i.e the initial node starting the recursion)
    /// - Returns: array of all nodes that are children, or children of children etc.. all the way down the tree
    func allChildren (includeSelf:Bool)-> [SelfType]
    
    /// Return the count of all children down the tree (optional: including self)
    
    
    /// Return the count of all the child nodes down thre tree (optional: including self)
    /// - Parameter includeSelf: should include self in the count
    /// - Returns: amount (count) of all children down the tree, if specified is incremented by 1 (for self)
    func allChildrenCount(includeSelf:Bool) -> Int
    
    /// List all parents of this node (recursive uptree)
    /// - Parameter includeSelf: determines if the recusion and result include self( i.e the initial node starting the recursion)
    /// - Returns: array of all nodes that are parent, or parent of parent etc.. all the way up the tree
    func allParents (includeSelf:Bool)-> [SelfType]
    
    
    /// List all children of this node (recursive downtree) as a dictionary of all nodes for a given depth by the key of their depth. Dictionary of arrays.
    /// One may assume the dictionary int keys will run from self.depth to the deepest node's depth
    /// - Parameter includeSelf: determines if the recusion and result include self( i.e the initial node starting the recursion)
    /// - Returns: array of all nodes that are parent, or parent of parent etc.. all the way up the tree
    func allChildrenByDepth (includeSelf:Bool)-> [Int:[SelfType]]
    
    /// List all parents of this node (recursive uptree) as a dictionary of each parent and its depth in the tree.
    /// One may assume the dictionary int keys will run from 0 to self.depth
    /// - Parameter includeSelf: determines if the recusion and result include self( i.e the initial node starting the recursion)
    /// - Returns: array of all nodes that are parent, or parent of parent etc.. all the way up the tree
    func allParentsByDepth (includeSelf:Bool)-> [Int:SelfType]
    
    // Required initializer
    init(id: IDType, value: ValueType?, parent newParent: SelfType?)
    
    // Debugging
    func treeDescription() -> [String]
}

public extension  MNTreeNodeProtocol where Self : Codable, ValueType : Codable, IDType : Codable {
    init(from decoder: Decoder) throws where Self: Codable, ValueType : Codable, IDType : Codable {
        dlog?.warning("MNTreeNodeProtocol \(Self.self) should implement init(from decoder: Decoder) throws!")
        throw MNError(code: .misc_failed_creating, reason: "failed decodable init for \(Self.self)")
    }
}

fileprivate let _cleanupKeyCharSet = CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines).union(.symbols)
public extension MNTreeNodeBaseProtocol /* default implementations */ {
    static var TREE_NODE_TYPE_KEY : String {
        if MNUtils.debug.IS_DEBUG {
            return "\(self)".replacingOccurrences(of: _cleanupKeyCharSet, with: "-") // More human-readable
        } else {
            return "\(self)"
        }
    }
    
    var TREE_NODE_TYPE_KEY : String {
        return Self.TREE_NODE_TYPE_KEY
    }
    
    // MARK: Equatable
    static func ==(lhs:Self, rhs:Self)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: HasHable
    func hash(into hasher: inout Hasher) {
        // NOTE: Non-persistant across sessions or instances!
        hasher.combine(MemoryAddress(of: self).rawValue)
        hasher.combine(id)
        hasher.combine(value)
        hasher.combine(parent)
        hasher.combine(children)
    }
}

public extension MNTreeNodeProtocol /* default implementations */ {
    /// List all children of this node (recursive downtree)
    /// NOTE: does NOT include self!
    var allChildren : [SelfType] { return self.allChildren(includeSelf: false) }
    
    /// Return the count (amount) of all children down the tree (not including self) (recursive downtree)
    var allChildrenCount : Int { return self.allChildrenCount(includeSelf: false) }

    /// List all children of this node (recursive downtree)
    /// NOTE: does NOT include self!
    var allParents : [SelfType] { return self.allParents(includeSelf: false) }

    /// List all children of this node (recursive downtree) as a dictionary of all nodes for a given depth by the key of their depth
    ///  One may assume the dictionary int keys will run from self.depth to the deepest node's depth
    /// NOTE: does NOT include self!
    var allChildrenByDepth : [Int:[SelfType]] { return self.allChildrenByDepth(includeSelf: false) }

    /// List all parents of this node (recursive uptree) as a dictionary each parent and its depth in the tree.
    ///  One may assume the dictionary int keys will run from 0 to self.depth
    /// NOTE: does NOT include self!
    var allParentsByDepth : [Int:SelfType] { return self.allParentsByDepth(includeSelf: false) }
}
