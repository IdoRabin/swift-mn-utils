//
//  IndexPathTuple.swift
//  bricks
//
//  Created by Ido on 02/12/2023.
//

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
    public var fromIndexPaths : [IndexPath] {
        return self.compactMap { item in
            item.fromIndexpath
        }
    }

    public var toIndexPaths : [IndexPath] {
        return self.compactMap { item in
            item.toIndexpath
        }
    }
    
    public var fromIndexes : [Int] {
        return self.compactMap { item in
            item.fromIndexpath.first
        }
    }
    
    public var toIndexes : [Int] {
        return self.compactMap { item in
            item.toIndexpath.first
        }
    }
}
