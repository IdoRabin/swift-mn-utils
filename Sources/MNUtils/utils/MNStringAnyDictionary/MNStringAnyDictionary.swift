//
//  MNStringAnyDictionary.swift
//  
//
//  Created by Ido on 19/03/2023.
//

import Foundation

fileprivate var codingRegisteredIffyClasses : [String:Any.Type] = [:]
fileprivate var codingRegisteredIffyPrefixes = Set<String>()

fileprivate let dlog : MNLogger? = nil // MNLog.forClass("MNStringAnyDictionary")

typealias MNStringAnyDictionary = Dictionary<String, Any>
typealias MNStringAnyCodableDictionary = Dictionary<String, Codable>

protocol MNStringAnyInitable {
    init(stringAnyDict dict:StringAnyDictionary) throws
    static func createInstance(stringAnyDict dict:MNStringAnyDictionary)->Self?
}
extension MNStringAnyInitable {
    static func createInstance(stringAnyDict dict:MNStringAnyDictionary)->Self? {
        do {
            return try Self.init(stringAnyDict: dict)
        } catch let error {
            dlog?.warning("Error: \(error.description)")
        }
        return nil
    }
}
