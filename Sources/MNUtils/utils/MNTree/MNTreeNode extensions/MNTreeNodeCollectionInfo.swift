//
//  MNTreeNodeCollectionInfo.swift
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

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeCollectionInfo") // ?.setting(verbose: false, testing: IS_TESTING)

struct MNTreeNodeCollectionInfo : Codable, Equatable, CustomStringConvertible, Hashable {
    enum CodingKeys : String, CodingKey, CaseIterable {
        case treesCount = "trees_count"
        case duplicateNodesCount = "duplicate_nodes_count"
        case totalNodesCount = "total_nodes_count"
        case maxDepth = "max_depth"
        case hashSum = "hash_sum"
    }
    
    let treesCount : Int
    let duplicateNodesCount : Int
    let totalNodesCount : Int // unique nodes!
    let maxDepth : Int
    let hashSum : Int
    
    // MARK: Lifecycle
    init(treesCount: Int, duplicateNodesCount: Int, totalNodesCount:Int, maxDepth:Int, hashSum:Int) {
        self.treesCount = treesCount
        self.duplicateNodesCount = duplicateNodesCount
        self.totalNodesCount = totalNodesCount
        self.maxDepth = maxDepth
        self.hashSum = hashSum
    }
    
    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(treesCount, forKey: CodingKeys.treesCount)
        if duplicateNodesCount > 0 {
            try container.encode(duplicateNodesCount, forKey: CodingKeys.duplicateNodesCount)
        }
        try container.encode(totalNodesCount, forKey: CodingKeys.totalNodesCount)
        try container.encode(maxDepth, forKey: CodingKeys.maxDepth)
        try container.encode(hashSum, forKey: CodingKeys.hashSum)
    }
    
    public init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        self.treesCount = try keyed.decode(Int.self, forKey: CodingKeys.treesCount)
        self.duplicateNodesCount = try keyed.decodeIfPresent(Int.self, forKey: CodingKeys.duplicateNodesCount) ?? 0
        self.totalNodesCount = try keyed.decode(Int.self, forKey: CodingKeys.totalNodesCount)
        self.maxDepth = try keyed.decode(Int.self, forKey: CodingKeys.maxDepth)
        self.hashSum = try keyed.decode(Int.self, forKey: CodingKeys.hashSum)
    }
    
    // MARK: Equatable
    static func ==(lhs:MNTreeNodeCollectionInfo, rhs:MNTreeNodeCollectionInfo)->Bool {
        guard lhs.hashSum == rhs.hashSum else {
            dlog?.notice("lhs.hashSum (\(lhs.hashSum)) != hs.hashSum (\(rhs.hashSum))")
            return false
        }
        return lhs.treesCount == rhs.treesCount &&
            lhs.treesCount == rhs.treesCount &&
            lhs.duplicateNodesCount == rhs.duplicateNodesCount &&
            lhs.totalNodesCount == rhs.totalNodesCount &&
            lhs.maxDepth == rhs.maxDepth &&
            lhs.hashSum == rhs.hashSum
    }
    
    // MARK: HasHable
    func hash(into hasher: inout Hasher) {
        hasher.combine(treesCount)
        hasher.combine(duplicateNodesCount)
        hasher.combine(totalNodesCount)
        hasher.combine(maxDepth)
        hasher.combine(hashSum)
    }
    
    var description : String {
        var dup = ""
        if duplicateNodesCount > 0 {
            dup = " duplicates: \(duplicateNodesCount) "
        }
        return "<\(Self.self) treesCount:\(treesCount) totalNodesCount:\(self.totalNodesCount) maxDepth:\(self.maxDepth) hash:\(self.hashSum)\(dup)>"
    }
}
