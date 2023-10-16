//
//  MNTNReconstructionItem.swift
//  
//
//  Created by Ido on 06/09/2023.
//

import Foundation

struct MNTNReconstructionItem <ValueType : Equatable, IDType:Equatable & Hashable> : Equatable, Hashable {
    
    // MARK: Types
    public enum DepthToReconstrut : Codable, Equatable, Hashable {
        case known(Int)
        case unknown
        
        // MARK: Equatable
        public static func ==(lhs:DepthToReconstrut, rhs:DepthToReconstrut)->Bool {
            switch (lhs, rhs) {
            case (.known(let lhsDepth), .known(let rhsDepth)): return lhsDepth == rhsDepth
            case (.unknown, .unknown): return true
            default:
                return false
            }
        }
        
        // MARK: Hashable
        public  func hash(into hasher: inout Hasher) {
            switch self {
            case .unknown:
                hasher.combine(0)
            case .known(let val):
                hasher.combine(val + 2048 /* probably lower than MAX_TREE_DEPTH of the specific tree */)
            }
            if self == .unknown {
                
            } else {
                hasher.combine(1)
            }
            
        }
        
        var depth : Int? {
            switch self {
            case .known(let depth): return depth
            case .unknown: return nil
            }
        }
    }
    
    // MARK: Properties / members
    let date : Date
    let id : IDType
    let depthToReconstruct : DepthToReconstrut
    let value : ValueType?
    let parentId : IDType?
    
    // MARK: Equatable
    public static func ==(lhs:Self, rhs:Self)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(id)
        hasher.combine(depthToReconstruct)
        hasher.combine(parentId)
        if let value = value as? any Hashable {
            hasher.combine(value)
        }
    }
}
