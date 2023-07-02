//
//  UnkeyedEncodingContainerEx.swift
//  Bricks
//
//  Created by Ido on 11/12/2023.
//

import Foundation
import AppKit
import DSLogger
// see also NSColorEx.swift for NSColor.hexString() etc..

fileprivate let dlog : MNLogger? = nil // MNLog.forClass("decodeStringAnyDict")
fileprivate let dlogWarnings : MNLogger? = MNLog.forClass("decodeStringAnyDict_")

public typealias LosslessStrEnum = LosslessStringConvertible & Codable
public typealias CodableHashable = Codable & Hashable
public typealias AnyCodable = Any & Codable
public typealias AnyEquatable = Any & Equatable

public struct TypeDescriptor {
    let name : String
    let type : Any.Type
    
    init(name:String, type:Any.Type) {
        self.name = name
        self.type = type
    }
    
    init(type:Any.Type) {
        self.init(name: "\(type)", type: type)
    }
}

extension TypeDescriptor : Hashable {
    
    // MARK: Equatable
    public static func == (lhs: TypeDescriptor, rhs: TypeDescriptor) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine("\(type)")
    }
}

//typealias AnyCodableEquatable = Any & Codable & Equatable
//typealias AnyCodableHashable = Any & Codable & Hashable

public extension UnkeyedEncodingContainer {
    
    mutating func encode(dic:[String:Any], encoder:Encoder) throws {
        for (key, value) in dic {
            dlog?.info("saving \(key) : \(type(of: value)) = \(value)")
            switch value {
            case let val as Bool: try self.encode("\(key) : Bool = \(val)")
                
            case let val as Int: try self.encode("\(key) : Int = \(val)")
            case let val as Int8: try self.encode("\(key) : Int8 = \(val)")
            case let val as Int16: try self.encode("\(key) : Int16 = \(val)")
            case let val as Int32: try self.encode("\(key) : Int32 = \(val)")
            case let val as Int64: try self.encode("\(key) : Int64 = \(val)")
                
            case let val as UInt: try self.encode("\(key) : UInt = \(val)")
            case let val as UInt8: try self.encode("\(key) : UInt8 = \(val)")
            case let val as UInt16: try self.encode("\(key) : UInt16 = \(val)")
            case let val as UInt32: try self.encode("\(key) : UInt32 = \(val)")
            case let val as UInt64: try self.encode("\(key) : UInt64 = \(val)")
                
            case let val as Float: try self.encode("\(key) : Float = \(val)")
            case let val as Double: try self.encode("\(key) : Double = \(val)")
            
            case let val as Date: try self.encode("\(key) : Date = \(val.timeIntervalSince1970)")
            case let val as NSColor: try self.encode("\(key) : NSColor = \(val.hexString() ?? "null")")
            // case let val as UUIDv5: try self.encode("\(key) : UUIDv5 = \(val.uuidString)")
            case let val as UUID: try self.encode("\(key) : UUID = \(val.uuidString)")
            
            case let val as LosslessStrEnum:
                let typeStr = String(reflecting:type(of: value))
                let valDesc = val.description
                try self.encode("\(key) : \(typeStr) = .\(valDesc)")
                
            case let val as LosslessStringConvertible:
                let typeStr = String(reflecting:type(of: value))
                let valDesc = val.description
                try self.encode("\(key) : \(typeStr) = \(valDesc)")
                
            case let val as String:
                try self.encode("\(key) : String = \(val)")
                
            case let val as Codable:
                
                let typeStr = String(reflecting:type(of: value))
                dlogWarnings?.warning("to support [String:Any] dictionary encodings, type [\(typeStr)] should support LosslessStrEnum or LosslessStringConvertible in order to support encoding value :\(val)")
                
            default:
                break
            }
        }
    }
}

fileprivate var codingRegisteredIffyClasses : [String:Any.Type] = [:]
fileprivate var codingRegisteredIffyPrefixes = Set<String>()

public typealias StringAnyDictionary = Dictionary<String, Any>
public typealias StringAnyCodableDictionary = Dictionary<String, Codable>

public protocol StringAnyInitable {
    init(stringAnyDict dict:StringAnyDictionary) throws
    static func createInstance(stringAnyDict dict:StringAnyDictionary)->Self?
}
public extension StringAnyInitable {
    static func createInstance(stringAnyDict dict:StringAnyDictionary)->Self? {
        do {
            return try Self.init(stringAnyDict: dict)
        } catch let error {
            dlog?.warning("Error: \(error.description)")
        }
        return nil
    }
}


public class StringAny {
    
}

public extension StringAnyDictionary {
    
    /// Returns true is the class was already registered for StringAnyDictionary / UnkeyedEncodingContainerEx decoding of custom classes.
    /// NOTE: All class names / type strings must be prefixed with the module name.
    /// Like so: "MyApp.MyCustomClass" If the class is not dot speerated at all, the current module name will be added as prefix by default before the test.
    /// - Parameter typeStr: type to be checked as string
    /// - Returns:true if this type was already registerd
    static func isTypeRegistered(typeStr : String)->Bool {
        return codingRegisteredIffyClasses[typeStr] != nil
    }
    
    
    /// Returns true is the class was already registered for StringAnyDictionary / UnkeyedEncodingContainerEx decoding of custom classes.
    /// - Parameter avalue: type to be checked
    /// - Returns:true if this type was already registerewd
    static func isTypeRegistered(_ avalue:Any)->Bool {
        if let _ = avalue as? Decodable.Type {
            let type = String(reflecting:avalue)
            return codingRegisteredIffyClasses[type] != nil
        } else {
            MNLog.misc["StringAnyDictionary"]?.warning("isClassRegistered: \(avalue) cannot be registered: it must conform to Decodable protocol")
        }
        return false
    }
    
    static func registerType(_ avalue:Any) {
        if let val = avalue as? Decodable.Type {
            let type = String(reflecting:avalue)
            codingRegisteredIffyClasses[type] = val
            let comps = type.components(separatedBy: ".")
            if comps.count > 1 {
                let prefix = comps.first!
                codingRegisteredIffyPrefixes.update(with: prefix)
            }
        } else {
            MNLog.misc["StringAnyDictionary"]?.warning("registerClass: \(avalue) cannot be registered: it must conform to Decodable protocol")
        }
    }
    
    func registerType(_ avalue:Any) {
        Self.registerType(avalue)
    }

    static func getFirstKeyEndingWith(suffix:String)->String? {
        var result : String? = nil
        for key in codingRegisteredIffyClasses.keysArray {
            if key.hasSuffixMatching("\\W\(suffix)") {
                result = key
                break;
            }
        }
        return result
    }
    
    static func getType(typeName:String)->TypeDescriptor? {
        var result = codingRegisteredIffyClasses[typeName]
        var foundPrefix = typeName.components(separatedBy: ".").first!
        if result == nil && !typeName.contains(".") {
            
            if MNUtils.debug.IS_DEBUG && codingRegisteredIffyPrefixes.count > 30 {
                dlog?.warning("codingRegisteredIffyPrefixes has > 30 prefixs! The prefixes are supposed to signify app / framework modules. Please refrain from abusing the prefixes.")
            }
            
            // Uses list of all known prefixes:
            for prefix in codingRegisteredIffyPrefixes {
                let compound = "\(prefix).\(typeName)"
                result = codingRegisteredIffyClasses[compound]
                if result != nil {
                    foundPrefix = prefix
                    break;
                }
            }
            
            // Iterates all keys!
            if result == nil, let key = self.getFirstKeyEndingWith(suffix:typeName) {
                foundPrefix = typeName.components(separatedBy: ".").first!
                result = codingRegisteredIffyClasses[key]
            }
        }
        
        if result == nil {
            return nil
        }
        return TypeDescriptor(name: foundPrefix, type: type(of: result))
    }
    
    
}

public class UnkeyedDecodingUtil {
    
    public static func decode(decoder:Decoder, key:String, typeName:String, value:String) throws ->Any? {
        var typeNameClean = typeName.replacingOccurrences(ofFromTo: ["Swift.":""])
        
        switch typeNameClean {
        case "UInt": return UInt(value)
        case "UInt8": return UInt8(value)
        case "UInt16": return UInt16(value)
        case "UInt32": return UInt32(value)
        case "UInt64": return UInt64(value)
        case "Int": return Int(value)
        case "Int8": return Int8(value)
        case "Int16": return Int16(value)
        case "Int32": return Int32(value)
        case "Int64": return Int64(value)
        case "Float": return Float(value)
        case "Double": return Double(value)
        case "Date": return Date(timeIntervalSince1970: TimeInterval(value)!)
        case "NSColor": if value != "null" { return value.colorFromHex()! }
        case "UUID": return UUID(uuidString: value)
        // ?? case "UUIDv5": return UUIDv5(uuidString: value)
        case "Bool": return Bool(value.trimmingPrefix("."))
        default:
            
            // Get the right type for this typeName:
            var aatype : (Any.Type)? = codingRegisteredIffyClasses[typeName]
            if aatype == nil, let found = StringAnyDictionary.getType(typeName: typeName) {
                aatype = found.type
                typeNameClean = "\(found.name).\(typeName)"
            }
            
            // If we found a type for this typeName:
            if let aatype = aatype {
                if let aatype = aatype as? LosslessStringConvertible.Type {
                    let val = aatype.init(value.trimmingPrefix("."))
                    // Logging
                    if MNUtils.debug.IS_DEBUG {
                        if dlog != nil {
                            dlog?.successOrFail(condition: val != nil, "decode: \(aatype) val:\(val.descOrNil)")
                        } else if val == nil {
                            dlogWarnings?.fail("decode: \(aatype) val:\(val.descOrNil)")
                        }
                    }
                    
                    return val
                } else if let aatype = aatype as? Codable.Type {
                    let val = try aatype.init(from:decoder)
                    dlog?.info("did decode: \(aatype) val:\(val)")
                    return val
                } else {
                    dlogWarnings?.note("UnkeyedDecodingContainer.decode(..) static - \(key) failed parsing \(typeName) = \(value) [found type:\(aatype.self)]")
                }
            } else {
                dlogWarnings?.note("UnkeyedDecodingContainer.decode(..) static - \(key) failed finding class \(typeName) for ")
            }
            break
        }
        return nil
    }
    
}

public extension UnkeyedDecodingContainer {
    
    mutating func decode(decoder:Decoder, key:String, typeName:String, value:String) throws ->Any? {
        return try UnkeyedDecodingUtil.decode(decoder: decoder, key: key, typeName: typeName, value: value)
    }
    
    /// Wil return a [String:Any] dictionary (heterogenous values) attempting to decode using multiple techniques, inlcudign Registered classes ()
    /// NOTEL Function may throw!
    /// - Parameter decoder: decoder to use
    /// - Returns: [String:Any] ditionary with all possible decoded values.
    mutating func decodeStringAnyDict(decoder:Decoder) throws ->[String:Any] {
        var result : [String:Any] = [:]

        if let count = self.count {
            for _ in 0..<count {
                let str : String = try self.decode(String.self)
                let parts = str.components(separatedBy: " = ")
                let keyEx = parts[0]
                let value = parts.suffix(from: 1).joined(separator: " = ")
                let keyParts = keyEx.components(separatedBy: " : ")
                let key = keyParts[0]
                let typeName = keyParts.suffix(from: 1).joined(separator: " : ")
                if let anyVal = try decode(decoder:decoder, key: key, typeName: typeName, value: value) {
                    result[key] = anyVal
                    dlog?.success("key [\(key)] : [\(type(of: anyVal))] = [\(anyVal)]")
                } else {
                    dlogWarnings?.warning("could not decode(key:typeName:value:) key [\(key)] : [\(typeName))] = [\(value)]")
                }
            }
        }
        
        return result
    }
}

extension Dictionary : LosslessStringConvertible where Key == String, Value == String {
     
    public init?(_ description: String) {
        self.init()
        
        dlog?.info("INIT Dictionary <String, String> for LosslessStringConvertible")
        let tuples = description.trimmingPrefix("[").trimmingSuffix("]").components(separatedBy: "\",")
        let chars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))
        for tuple in tuples {
            let pairs = tuple.components(separatedBy: "\":")
            if pairs.count > 1 {
                let one = pairs.first!.trimmingCharacters(in: chars)
                let two = pairs[1...pairs.count - 1].joined(separator: "").trimmingCharacters(in:chars)
                dlog?.info("INIT Dictionary     ==> [\(one)] == \(two) <==")
                self[one] = two
            }
        }
    }
    
}
