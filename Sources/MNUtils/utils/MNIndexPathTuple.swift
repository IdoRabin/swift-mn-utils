//
//  IndexPathTuple.swift
//  bricks
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public struct MNIndexPathTuple<Element:Any> {
    let element : Element?
    let indexpath : IndexPath?
    var isEmpty : Bool { return element == nil && indexpath == nil }
}

public extension Dictionary where Key == IndexPath {
    func toIIndexPathTuples()->[MNIndexPathTuple<Value>] {
        return self.map { key, val in
            return MNIndexPathTuple(element: val, indexpath: key)
        }
    }
}

public struct MNMoveIndexPathTuple : Hashable {
    public let fromIndexpath : IndexPath
    public let toIndexpath : IndexPath
    
    public init(from:IndexPath, to:IndexPath) {
        fromIndexpath = from
        toIndexpath = to
    }
    
    public init(from:Int, to:Int) {
        fromIndexpath = IndexPath(index: from)
        toIndexpath = IndexPath(index: to)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fromIndexpath)
        hasher.combine(toIndexpath)
    }
}

public extension Sequence where Element == MNMoveIndexPathTuple {
    var fromIndexPaths : [IndexPath] {
        return self.compactMap { item in
            item.fromIndexpath
        }
    }

    var toIndexPaths : [IndexPath] {
        return self.compactMap { item in
            item.toIndexpath
        }
    }
    
    var fromIndexes : [Int] {
        return self.compactMap { item in
            item.fromIndexpath.first
        }
    }
    
    var toIndexes : [Int] {
        return self.compactMap { item in
            item.toIndexpath.first
        }
    }
}
