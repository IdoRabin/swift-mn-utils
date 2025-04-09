//
//  Array+MNTreeNode.swift
//  MNUtils
//
//  Created by ido on 19/10/2024.
//

import Foundation
// import DSLogger
import MNMacros

// ======================== Sequence extension =============================
// fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNode")

public extension Sequence where Element : MNTreeNode<AnyHashable, AnyHashable> {
    // MARK: HasHable
    func nodesHashValue()-> Int {
        let hash = self.ids.reduce(0) { partialResult, nodeId in
            // XOR is commutative, associative, and has the property that it effectively combines bits from multiple inputs while still allowing a good degree of randomness in the resulting hash
            return nodeId.hashValue ^ partialResult
        }
        // hasher.combine(self.ids.count)
        return hash
    }
}

public extension Sequence where Element : MNTreeNodeProtocol { // , Element.IDType : Equatable
    
    // MARK: HasHable
    func nodesHashValue()-> Int {
        let hash = self.ids.reduce(0) { partialResult, nodeId in
            // XOR is commutative, associative, and has the property that it effectively combines bits from multiple inputs while still allowing a good degree of randomness in the resulting hash
            return nodeId.hashValue ^ partialResult
        }
        // hasher.combine(self.ids.count)
        return hash
    }
    
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

public extension Sequence where Element : MNTreeNodeProtocol, Element.IDType : Any {
    var idDescriptions : [String] {
        return self.map { elem in
            return "\(elem.id)"
        }
    }
}


public extension Sequence where Element == MNTreeNode<AnyHashable, AnyHashable> {
    
    var nodesById : [Element.IDType:Element] {
        return self.toDictionary { element in
            element.id
        }
    }
    
}

// MARK: MNTreeNode sorting
@SimplifiedEnum
public enum MNTreeNodeSortMethod {
    case noSorting
    case byChildrenCount
    case byIDHashess
    case byComperableIDs
    case byComperableValues
    case custom((any MNTreeNodeProtocol, any MNTreeNodeProtocol)->Bool)
}

public typealias MNTreeNodeSorting = (method:MNTreeNodeSortMethod, isAscending:Bool)

public extension Sequence where Element : MNTreeNodeProtocol {
    
    /// Returns the same array, but sorted so that elements with less children are first, or later. Will sort equal child-count nodes by comparing the ids' raw hash values.
    /// - Parameter byChildrenAscending: will sort from nodes with lowest number or children to height, when false, will return the reverse.
    /// - Returns: array of MNTreeNodes sorted by amount of children for each node in the array.
    @inlinable public func sorted(byChildrenCountAscending isAscending:Bool) -> [Element] {
        return self.sorted { chld1, chld2 in
            if (chld1.children.count == chld1.children.count) {
                // Sub-sorting
                // This is used to persist the order as much as possible (for example, for identical order when encoding / decoding)
                
                // By id hash value
                return isAscending ?
                    (chld1.id.hashValue < chld2.id.hashValue) :
                    (chld1.id.hashValue > chld2.id.hashValue)
            }
            return isAscending ?
                // By children amount
                (chld1.children.count < chld2.children.count) :
                (chld1.children.count > chld2.children.count)
        }
    }
    
    /// Sorts the array of MNTreeNodes according to the hash values of the ids of the nodes.
    /// - Parameter isAscending: whether to sort in ascending order or not.
    /// - Returns: the sorted array of MNTreeNodes.
    @inlinable func sorted(byIDHashessAscending isAscending:Bool) -> [Element] {
        return self.sorted { chld1, chld2 in
            return isAscending ?
                (chld1.id.hashValue < chld2.id.hashValue) :
                (chld1.id.hashValue > chld2.id.hashValue)
        }
    }
    
    ///  Sorts the array of MNTreeNodes according to the ids of the nodes. (assuming the ids are Comparable)
    /// - Parameter isAscending: whether to sort in ascending order or not.
    /// - Returns: the sorted array of MNTreeNodes.
    
    @inlinable func sorted(byIDsAscending isAscending:Bool) -> [Element] where Element.IDType : Comparable {
        return self.sorted { chld1, chld2 in
            // NOTE: Not supposed to have 2 children in the same list with the same id.
            return isAscending ?
                (chld1.id < chld2.id) :
                (chld1.id > chld2.id)
        }
    }
    
    ///  Sorts the array of MNTreeNodes according to the values of the nodes. (assuming the values are Comparable)
    /// - Parameter isAscending: whether to sort in ascending order or not.
    /// - Returns: the sorted array of MNTreeNodes.
    
    @inlinable func sorted(byValuessAscending isAscending:Bool) -> [Element] where Element.ValueType : Comparable {
        return self.sorted { chld1, chld2 in
            if let val1 = chld1.value {
                if let val2 = chld2.value {
                    if (val1 == val2) {
                        // Sub-sorting, when the values themselves are equal.
                        // This is used to persist the order as much as possible (for example, for identical order when encoding / decoding)
                        return isAscending ?
                            (chld1.id.hashValue < chld2.id.hashValue) :
                            (chld1.id.hashValue > chld2.id.hashValue)
                    }
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
    
    /// Sorts the array of MNTreeNodes according to the given sorting method.
    /// - Parameter sorting: the sorting method to use.
    /// - Returns: the sorted array of MNTreeNodes.
    @inlinable func sorted(by sorting : MNTreeNodeSorting) -> [Element] {
        return self.sorted(by: sorting.method, isAscending: sorting.isAscending)
    }

    /// Sorts the array of MNTreeNodes according to the given sorting method.
    /// - Parameters:
    ///   - method:  the sorting method to use.
    ///   - isAscending: whether to sort in ascending order or not.
    /// - Returns: the sorted array of MNTreeNodes.
    @inlinable func sorted(by method:MNTreeNodeSortMethod, isAscending:Bool) -> [Element] {
//        if Element is Comparable && ![MNTreeNodeSortMethod.byComperableValues, .byComperableIDs].contains(method) {
//            dlog?.error("Element \(Element.self) is not Comparable, cannot sort by \(method)")
//            return self as! [Element]
//        }
//
//        switch method {
//        case .noSorting: 
//            return self // will be copied if mutated in caller
//        case .byChildrenCount:
//            return self.sorted(byChildrenCountAscending: isAscending)
//        case .byIDHashess:
//            return self.sorted(byIDHashessAscending: isAscending)
//        case .byComperableIDs:
//            return self.sorted(byIDsAscending: isAscending)
//        case .byComperableValues:
//            return self.sorted(byValuessAscending: isAscending)
//        case .custom(let customSort):
//            return self.sorted { chld1, chld2 in
//                return customSort(chld1, chld2)
//            }
//        }
        return []
    }
}
