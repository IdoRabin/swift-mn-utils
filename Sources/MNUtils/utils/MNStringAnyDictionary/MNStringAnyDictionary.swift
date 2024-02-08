//
//  MNStringAnyDictionary.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate var codingRegisteredIffyClasses : [String:Any.Type] = [:]
fileprivate var codingRegisteredIffyPrefixes = Set<String>()

fileprivate let dlog : Logger? = Logger(label: "MNStringAnyDictionary") // ?.setting(verbose: true)

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
