//
//  JSONSerializable.swift
//  
//
//  Created by Ido Rabin on 25/11/2022.
//  Copyright © 2022 . All rights reserved.
//

import Foundation
import DSLogger

fileprivate let dlog : MNLogger? = MNLog.forClass("JSONSerializable")

public extension JSONEncoder {
    func encodeJSONObject<T: Encodable>(_ value: T, options opt: JSONSerialization.ReadingOptions = []) throws -> Any {
        let data = try encode(value)
        return try JSONSerialization.jsonObject(with: data, options: opt)
    }
}

public extension JSONDecoder {
    static let RAW_JSON_USER_INFO_KEY = "raw_json_object"
    
    func decode<T: Decodable>(_ type: T.Type, withJSONObject object: Any, options opt: JSONSerialization.WritingOptions = []) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: opt)
        // dlog?.info("Decoding JSON object to: \(T.self) >> ")
        self.setUserInfo(object, forKey: Self.RAW_JSON_USER_INFO_KEY)
        return try decode(T.self, from: data)
    }
}

extension String : JSONSerializable {
    
}

public extension Dictionary where Key : JSONSerializable, Value : JSONSerializable {
    /// Will Serialize each element in the array to a json dictionary
    ///
    /// - Parameter isForRemote: each JSONSerializable may use this to override its serialization process, for "remote" (i.e sending via API) vs. local uses
    /// - Returns: an a array of [String:Any] dictionaries, i.e "JSON" dictionaries
    func serializeToJsonDictionaries(isForRemote:Bool = false)->[String:Any] {
        var result : [String:Any] = [:]
        for (key, val) in self {
            let skey = (key is String) ? key as! String :  key.serializeToJsonString(prettyPrint: false)!
            
            switch val {
                // TODO: Add more base types etc
            case is String:
                result[skey] = val as! String
            default:
                result[skey] = val.serializeToJsonDictionary(isForRemote:isForRemote)!
            }
            
        }
        return result
    }
    
    func serializeToJsonString(isForRemote:Bool = false, prettyPrint:Bool = false)->String? {
        var result : [String:Any] = [:]
        
        // Build codable string keyed dictionary
        for (key, val) in self {
            // TODO: how to user isForRemote?
            let skey = (key is String) ? key as! String :  key.serializeToJsonString(prettyPrint: false)!
            
            switch val {
                // TODO: Add more base types etc
            case is String:
                result[skey] = val as! String
            default:
                result[skey] = val.serializeToJsonString(prettyPrint: prettyPrint)!
            }
        }
        
        // Build string
        let ln = prettyPrint ? "\n" : " "
        let tab = prettyPrint ? "\t" : ""
        var resultStr = "{" + ln
        var count = 0
        for (key, val) in result {
            resultStr += tab + "'\(key)' : '\(val)'"
            count += count
            if count < result.count - 1 {
                resultStr += ","
            }
            resultStr += ln
        }
        resultStr += "}"
        
        return resultStr
    }
}

public extension Array where Element : JSONSerializable {
    
    
    /// Will Serialize each element in the array to a json dictionary
    ///
    /// - Parameter isForRemote: each JSONSerializable may use this to override its serialization process, for "remote" (i.e sending via API) vs. local uses
    /// - Returns: an a array of [String:Any] dictionaries, i.e "JSON" dictionaries
    func serializeToJsonDictionaries(isForRemote:Bool = false)->[[String:Any]] {
        var result : [[String:Any]] = []
        for item in self {
            if let json = item.serializeToJsonDictionary(isForRemote : isForRemote) {
                result.append(json)
            }
        }
        return result
    }
    
    func serializeToJsonString(isForRemote:Bool = false, prettyPrint:Bool = false)->String? {
        let ln = prettyPrint ? "\n" : " "
        let tab = prettyPrint ? "\t" : ""
        
        var resultStr = "{" + ln
        var count = 0
        
        // Build result string
        for val in self {
            // TODO: how to user isForRemote?
            var valStr : String? = nil
            switch val {
                // TODO: Add more base types etc
            case is String:
                valStr = val as? String
            default:
                valStr = val.serializeToJsonString(prettyPrint: prettyPrint)!
            }
            
            resultStr += tab + "\(valStr ?? "nil")"
            count += 1
            
            if count < self.count {
                resultStr += ","
            }
            
            resultStr += ln
        }
        resultStr += "}"
        
        return resultStr
    }
}

/// Protocol declating convenience method for serializing/ deserializing Codable objects to/from JSON
public protocol JSONSerializable : Codable {
    func serializeToJsonData(prettyPrint:Bool)->Data?
    func serializeToJsonString(prettyPrint:Bool)->String?
    static func deserializeFromJsonData<AType:Decodable>(data:Data?)->AType?
    static func deserializeFromJsonString<AType:Decodable>(string:String?)->AType?
    
    func didDeserializefromJson()
    func didSerializeToJson()
}

public extension JSONSerializable {
    
    func didDeserializefromJson() {
        
    }
    
    func didSerializeToJson() {
        
    }
    
    /// Serialized any codable object into a JSON string and returned as the Data for that string
    ///
    /// - Returns: Data for a json string representing the object
    func serializeToJsonData(prettyPrint:Bool = false)->Data? {
        let encoder = MNJSONEncoder()
        if (prettyPrint) {
            encoder.outputFormatting.update(with: JSONEncoder.OutputFormatting.prettyPrinted)
        }
        
        do {
            let result = try encoder.encode(self)
            self.didSerializeToJson()
            return result
        } catch {
            return nil
        }
    }
    
    
    /// Serializes the object to a JSON strong. default is NOT pretty string.
    /// - Parameter prettyPrint:resulting JSON will have newLine and other decorations to make it pretty and easily readable.
    /// - Returns: a decodable JSON string descrobing the codable object.
    func serializeToJsonString(prettyPrint:Bool = false)->String? {
        if let data = self.serializeToJsonData(prettyPrint:prettyPrint) {
            let result = String(data: data, encoding: String.Encoding.utf8)
            self.didSerializeToJson()
            return result
        }
        
        return nil
    }
    /// Serialized any codable object into a JSON dictionary
    ///
    /// - Returns: Data for a json string representing the object
    func serializeToJsonDictionary(isForRemote:Bool = false)->[String:Any]? {
        let encoder = MNJSONEncoder()
        do {
            // TODO: implement isForRemote mechanisem to override some serializations
            let data = try encoder.encode(self)
            let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any]
            self.didSerializeToJson()
            return result
        } catch {
            return nil
        }
    }
    
    
    /// Will attempt deserializing Data into a Decodable object
    ///
    /// - Parameter data: provided data to deserialize
    /// - Returns: A Decodable object
    static func deserializeFromJsonData<AType:Decodable>(data:Data?)->AType? {
        guard let data = data else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(AType.self, from: data)
            (result as? JSONSerializable)?.didDeserializefromJson()
            return result
        } catch let error as NSError {
            let appErr = MNError(error: error)
            dlog?.note("Decoding of \(type(of: self)) faild with error:\(appErr)")
            return nil
        }
    }
    
    static func deserializeFromJsonString<AType:Decodable>(string:String?)->AType? {
        if let string = string, let data = string.data(using: String.Encoding.utf8) {
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(AType.self, from: data)
                (result as? JSONSerializable)?.didDeserializefromJson()
                return result
            } catch let error as NSError {
                dlog?.note("Failed deserializing from JSON: error: \(error.code) > \(error.localizedDescription) > \(String(describing: error))")
                return nil
            }
        }
        return nil
    }
}

public typealias StringStringDistionary = [String:String]

extension StringStringDistionary : JSONSerializable {
    
}

public protocol JSONFileSerializable : JSONSerializable {
    
    ///
    /// - Parameter path: path to save into
    
    
    
    /// Save (encode) self as JSON into the given path
    /// - Parameters:
    ///   - path: local filesystem path (caller must validate path exists and reachanble)
    ///   - prettyPrint: pretty print json or compact mode
    func saveToJSON(_ fileurl:URL, prettyPrint:Bool)->Result<Void, Error>
    
    
    /// Will load (decode) self, expecting a JSON file in the given path
    /// - Parameter fileurl: file url for the file. NOTE: the function checks for "file exists" and returns nil if not.
    /// - Returns: a loaded instance of Self type
    static func loadFromJSON<T>(_ fileurl: URL) -> Result<T, Error> where T : JSONFileSerializable
}

public extension JSONFileSerializable {
    func saveToJSON(_ fileurl:URL, prettyPrint:Bool)->Result<Void, Error> {
        do {
            
            // Remove exiating file if needed
            if FileManager.default.fileExists(atPath: fileurl.path) {
                try FileManager.default.removeItem(at: fileurl)
            }
            
            if let data = self.serializeToJsonData(prettyPrint: prettyPrint) {
                FileManager.default.createFile(atPath: fileurl.path, contents: data, attributes: nil)
                if MNUtils.debug.IS_DEBUG {
                    if data.count > 1000000 { // 1MB
                        dlog?.note("Maybe saving a > 1MB JSON as string is not efficient, consider using another encoder!")
                    }
                    // dlog?.info("saveToJSON size: \(data.count) file: \(fileurl) prettyPrint: \(prettyPrint)")
                }
            } else {
                throw MNError(.misc_failed_saving, reason:"saveToJSON failed with: \(fileurl.lastPathComponent)")
            }
            
            return .success(Void())
        } catch let error {
            let desc = "saveToJSON failed to save into file: \(fileurl.lastPathComponent)"
            dlog?.warning("\(desc) error:\(MNError(error: error))")
            return .failure(MNError(code:MNErrorCode.misc_failed_saving, reason: desc, underlyingError: error))
        }
    }
    
    static func loadFromJSON<T>(_ fileurl: URL) -> Result<T, Error> where T : JSONFileSerializable {
        guard T.self == Self.self else {
            return .failure(MNError(code: .misc_failed_loading, reason: "loadFromJSON<T> where T must equal Self (type of class being operated on)"))
        }
    // static func loadFromJSON(_ fileurl:URL)->Result<Self, Error> {
        if FileManager.default.fileExists(atPath: fileurl.path) {
            do {
                let data = try Data(contentsOf: fileurl)
                let decoder = JSONDecoder()
                // Magic prefix bytes?
                
                let result : Self = try decoder.decode(Self.self, from: data)
                if MNUtils.debug.IS_DEBUG {
                    if data.count > 1000000 { // 1MB
                        dlog?.note("Maybe loading a > 1MB JSON as string is not efficient, consider using another encoder!")
                    }
                }
                return .success(result as! T)
                
            } catch let error {
                let desc = "loadFromJSON File \"...\(fileurl.lastPathComponents(count: 3))\" parse / load error:\(MNError(error: error))"
                dlog?.note(desc)
                return .failure(MNError(code:.misc_failed_loading, reason: desc, underlyingError: error))
            }
        } else {
            dlog?.note("loadFromJSON File \"...\(fileurl.lastPathComponents(count: 3))\" does not exit")
            return .failure(MNError(MNErrorCode.misc_failed_loading, reason: "loadFromJSON failed - file does not exist: \(fileurl.path) "))
        }
    }
}
