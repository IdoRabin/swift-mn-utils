//
//  IndexPathTuple.swift
//  bricks
//
//  Created by Ido on 02/12/2023.
//

import Foundation

struct MNIndexPathTuple<Element:Any> {
    let element : Element?
    let indexpath : IndexPath?
    var isEmpty : Bool { return element == nil && indexpath == nil }
}

extension Dictionary where Key == IndexPath {
    func toIIndexPathTuples()->[MNIndexPathTuple<Value>] {
        return self.map { key, val in
            return MNIndexPathTuple(element: val, indexpath: key)
        }
    }
}

struct MNMoveIndexPathTuple : Hashable {
    let fromIndexpath : IndexPath
    let toIndexpath : IndexPath
    
    init(from:IndexPath, to:IndexPath) {
        fromIndexpath = from
        toIndexpath = to
    }
    
    init(from:Int, to:Int) {
        fromIndexpath = IndexPath(index: from)
        toIndexpath = IndexPath(index: to)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fromIndexpath)
        hasher.combine(toIndexpath)
    }
}

extension Sequence where Element == MNMoveIndexPathTuple {
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
