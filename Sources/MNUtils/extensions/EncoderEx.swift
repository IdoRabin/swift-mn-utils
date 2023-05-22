//
//  EncoderEx.swift
//  
//
//  Created by Ido on 06/12/2022.
//

import Foundation

fileprivate let dlog : MNLogger? = MNLog.forClass("EncoderEx")
fileprivate let APP_STRING_PREFERENCE_KEY = "IS_STRING_PREFERENCE"

extension Decoder {
    func getUserInfo(forKey key: String) -> Any? {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        return userInfo[infoKey]
    }
    
    var isJSONStringPreference : Bool {
        get {
            return (self as? JSONEncoder)?.isStringPreference ?? false
        }
    }
}

extension JSONDecoder {
    func setUserInfo(_ info: Any?, forKey key: String) {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        userInfo[infoKey] = info
    }
}

extension JSONEncoder {
    func getUserInfo(forKey key: String) -> Any? {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        return userInfo[infoKey]
    }
    
    func setUserInfo(_ info: Any?, forKey key: String) {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        userInfo[infoKey] = info
    }
}

extension Encoder {
    public static func isJSONEncoder(encoder: Encoder)->Bool {
        // dlog?.info("isJSONEncoder \(type(of:self)) - userInfo:\(encoder.userInfo) path:\(encoder.codingPath)")
        return "\(type(of:self))".lowercased().contains("jsonencoder") || ((self as? JSONEncoder.Type) != nil)
    }
    
    public var isJSONEncoder : Bool {
        return Self.isJSONEncoder(encoder:self)
    }
    
    var isJSONStringPreference : Bool {
        get {
            return (self as? JSONEncoder)?.isStringPreference ?? false
        }
    }
}

extension JSONEncoder {
    var isStringPreference : Bool {
        get {
            return (self.getUserInfo(forKey:APP_STRING_PREFERENCE_KEY) as? Bool) ?? false == true
        }
        set {
            self.setUserInfo(newValue, forKey: APP_STRING_PREFERENCE_KEY)
        }
    }
}
