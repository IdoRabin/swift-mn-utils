//
//  MNStringAnyDictionary.swift
//  
//
//  Created by Ido on 19/03/2023.
//

import Foundation
import DSLogger

fileprivate var codingRegisteredIffyClasses : [String:Any.Type] = [:]
fileprivate var codingRegisteredIffyPrefixes = Set<String>()

fileprivate let dlog : MNLogger? = nil // MNLog.forClass("MNStringAnyDictionary")

public typealias MNStringAnyDictionary = Dictionary<String, Any>
public typealias MNStringAnyCodableDictionary = Dictionary<String, Codable>

public protocol MNStringAnyInitable {
    init(stringAnyDict dict:StringAnyDictionary) throws
    static func createInstance(stringAnyDict dict:MNStringAnyDictionary)->Self?
}
public extension MNStringAnyInitable {
    static func createInstance(stringAnyDict dict:MNStringAnyDictionary)->Self? {
        do {
            return try Self.init(stringAnyDict: dict)
        } catch let error {
            dlog?.warning("Error: \(error.description)")
        }
        return nil
    }
}
