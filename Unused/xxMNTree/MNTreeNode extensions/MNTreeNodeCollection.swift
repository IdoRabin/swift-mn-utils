//
//  MNTreeNodeCollection.swift
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

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeCollection") // ?.setting(verbose: false, testing: IS_TESTING)

public class MNTreeNodeCollection : Codable, Hashable, Equatable {
    
    struct UniquedRecord {
        let nodes : [any MNTreeNodeProtocol]
        let duplicateRootNodeIds : [String]
        
        var countOfAllNodesDownTrees: Int {
            var result = 0
            
            for node in self.nodes {
                if !node.isChildOf(anyIn: self.nodes) {
                    result += node.allChildrenCount(includeSelf: true)
                }
            }
            
            return result
        }
    }
    
    // MARK: Coding keys
    enum CodingKeys : String, CodingKey, CaseIterable {
        case info = "tree_collection_info"
        case collection = "tree_collection"
        case duplicateRootIds = "duplicate_root_ids"
    }
    
    let nodes : [any MNTreeNodeProtocol]
    var isEncodeAllTreesFlat : Bool? = false // Override config for each tree..
    var isEncodeCollectionInfo : Bool = false
    
    init(nodes newNodes:[any MNTreeNodeProtocol]) {
        nodes = newNodes
    }

    /// Returns all the nodes in all the collection including each node's downtree nodes:
    /// NOTE: may return duplicate appearances of the same instance!
    var allNodesDownTrees: [any MNTreeNodeProtocol] {
        var result : [any MNTreeNodeProtocol] = []
        for node in self.nodes {
            if let all = node.allChildren as? [any MNTreeNodeProtocol] {
                result.append(contentsOf: all)
            }
        }
        return result
    }
    
    
    /// Returns count of all nodes in the collection's top level
    /// NOTE: may return duplicate appearances of the same instance!
    var count : Int {
        return self.nodes.count
    }
    
    var maxDepth: Int {
        var result = 0
        for node in self.nodes {
            node.recourseChildren({ node, depth in
                if let node = node as? any MNTreeNodeProtocol, node.isLeaf {
                    result = max(result, depth)
                }
            }, method: .depthFirst, stopTest: nil, includeSelf: true)
        }
        
        return result
    }
    
    var collectionInfo : MNTreeNodeCollectionInfo {
        let uniqued = self.uniqueNodes()
        return MNTreeNodeCollectionInfo(treesCount: uniqued.nodes.count,
                                        duplicateNodesCount: uniqued.duplicateRootNodeIds.count,
                                        totalNodesCount: uniqued.countOfAllNodesDownTrees,
                                        maxDepth: self.maxDepth,
                                        hashSum: self.hashValue)
    }
    
    func uniqueNodes()->UniquedRecord {
        var resultNodes : [any MNTreeNodeProtocol] = []
        var repeatedNodeIds : [String] = []
        
        // Cleate a "cleared nodes" array of verified, non repeating nodes
        for node in self.nodes {
            if !node.isChildOf(anyIn: nodes) {
                resultNodes.append(node)
            } else {
                repeatedNodeIds.append("\(node.id)")
            }
        }
        
        return UniquedRecord(nodes: resultNodes, duplicateRootNodeIds: repeatedNodeIds)
    }
    
    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var itemsContainer = container.nestedUnkeyedContainer(forKey: .collection)
        let uniqued = self.uniqueNodes()
        
        // Override all tree isEncodeFlat in configs if needed:
        var prevIsFlatConfigValues : [String:Bool] = [:]
        if let isEncodeAllTreesFlat = self.isEncodeAllTreesFlat {
            
            // Save state:
            prevIsFlatConfigValues = uniqued.nodes.toDictionary(keyForItem: { node in
                "\(node.id)"
            }, itemForItem: { key, node in
                node.config.isEncodeFlat
            })
            
            // Change state:
            uniqued.nodes.forEach { node in
                node.config.isEncodeFlat = isEncodeAllTreesFlat
            }
        }
        
        dlog?.info("---- TreeNodeCollection with (\(uniqued.nodes.count)) items will encode. isAllFlat: \(self.isEncodeAllTreesFlat.descOrNil) ----")
        
        // 1. Encode collection items / nodes and collect some info:
        // All collection "nodes" that are not cyclic or problematic:
        for node in uniqued.nodes {
            if let cnode = node as? Codable {
                dlog?.verbose("TreeNodeCollection will encode: \(node.id)")
                try itemsContainer.encode(cnode)
            } else {
                dlog?.notice("TreeNodeCollection failed encoding \( "\(node)" ) : is NOT codable!")
            }
        }
        
        // Encode duplicate ids in the root of the collection:
        if uniqued.duplicateRootNodeIds.count > 0 {
            try container.encode(uniqued.duplicateRootNodeIds, forKey: .duplicateRootIds)
        }
        
        // Revert all isEncodeFlat in tree configs (if needed)
        if prevIsFlatConfigValues.count > 0 {
            for node in self.nodes {
                if let val = prevIsFlatConfigValues["\(node.id)"] {
                    node.config.isEncodeFlat = val // set previous value into the config
                }
            }
        }
        
        // 2. Encode tree collection Info:
        if self.isEncodeCollectionInfo {
            try container.encode(self.collectionInfo, forKey: .info)
        }
    }
    
    public func logCollectionTree(ctx:String) {
        guard let dlog = dlog else {
            return
        }
        
        let totalCount = self.nodes.count
        var lines = ["collection #hash: \(self.hashValue) (\(totalCount) items)", "["]
        self.nodes.forEachIndex { index, node in
            lines.append("  [\(index + 1)/\(totalCount)] nodes tree:")
            lines.append(contentsOf: node.treeDescription())
        }
        lines.append("]")
        dlog.info("\(lines.joined(separator: "\n"))")
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        dlog?.info("|dec| \(Self.self) init(from decoder:)")
        
        // 2. Decode tree collection Info:
        var decodedInfo : MNTreeNodeCollectionInfo? = nil
        if container.allKeys.contains(elementEqualTo: .info) {
            decodedInfo = try container.decode(MNTreeNodeCollectionInfo.self, forKey: .info)
            dlog?.info("|dec| found collection info. \(decodedInfo.descOrNil)")
        }
        
        // 1. Decode trees:
        var newNodes : [any MNTreeNodeProtocol] = []
        var nodesContainer = try container.nestedUnkeyedContainer(forKey: .collection)
        
        dlog?.info("|dec| MNTreeNodeCollection decoding (\(nodesContainer.count ?? 0) root nodes.)")
        while !nodesContainer.isAtEnd {
            do {
                if let aSingleTree = try nodesContainer.decodeIfPresent(UnknownMNTreeDecodingObj.self), let node = aSingleTree.instance {
                    newNodes.append(node)
                    if dlog != nil {
                        // let nodeAsProt = node as! any MNTreeNodeProtocol
                        let record = UnknownMNTreeDecodingObj.getNodeTypeRecord(byKey: node.TREE_NODE_TYPE_KEY)
                        dlog?.success("|dec| collection decoded tree: \"\(node.id)\" record: \(record.descOrNil)")
                    }
                }
            } catch let error {
                throw MNError(code: .misc_failed_decoding, reason: "\(Self.self) |dec| failed decoding tree node. underlying error:\n\(error.description)", underlyingError: error)
            }
        }
        
        
        // Decode duplicate ids in the root of the collection:
        if container.allKeys.contains(elementEqualTo: .duplicateRootIds) {
            let idStrings = try container.decode([String].self, forKey: .duplicateRootIds)
            dlog?.info("|dec| MNTreeNodeCollection found duplicate root ids: \(idStrings)")
            for node in newNodes {
                if let foundNode = node.firstChildDowntree(where: { node, depth in
                    if let node = node as? any MNTreeNodeProtocol {
                        return idStrings.contains("\(node.id)")
                    }
                    return false
                }, includeSelf: true, method: .breadthFirst) as? any MNTreeNodeProtocol {
                    // use foundNode
                    newNodes.append(foundNode) // add all duplicate nodes at end.
                }
            }
        }
        
        self.nodes = newNodes
        self.logCollectionTree(ctx:"Decoded")
        
        if let decodedInfo = decodedInfo {
            // validate loaded structures?
            let selfInfo = self.collectionInfo
            if decodedInfo == selfInfo {
                dlog?.success("|dec| MNTreeNodeCollectionInfo validation matches the resulting collection info!\n      decoded: \(decodedInfo) \n         self: \(selfInfo)")
            } else {
                // Decoding went wrong:
                dlog?.warning("|dec| MNTreeNodeCollectionInfo does ❌ NOT match the resulting collection info!\n      decoded: \(decodedInfo) \n         self: \(selfInfo)")
            }
        }
        
        // throw MNError(code: .misc_failed_decoding, reason: "\(Self.self) failed decoding for an unknown reason")
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        // NOTE: ignore isEncodeAllTreesFlat, isEncodeCollectionInfo
        for node in nodes {
            hasher.combine(node.hashValue)
        }
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNTreeNodeCollection, rhs:MNTreeNodeCollection)->Bool {
        // NOTE: ignore isEncodeAllTreesFlat, isEncodeCollectionInfo
        return lhs.hashValue == rhs.hashValue
    }
}
