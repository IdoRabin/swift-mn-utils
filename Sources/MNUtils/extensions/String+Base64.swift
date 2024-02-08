//
//  String+Base64.swift
//  Base64 extensions with String
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label:"String+Base64")

public extension String  /* base64 */ {
    
    /// Will try to convert the string back from base64 into a string, trying first utf8 encoding, and as a fallback utf16 encoding. If both methods fail, will throw an error
    /// - Returns: Original string before it was converted to base 64
    func fromBase64Throws() throws -> String{
        let encodingsToTry : [String.Encoding] = [.utf8, .utf16]
        if let data = Data.init(base64Encoded: self, options: .ignoreUnknownCharacters) { // self.data(using: encoding), data.count > 0 {
            for encoding in encodingsToTry {
                if let str = String(data: data, encoding: encoding) {
                    return str
                }
            }
        }
        
//        if let data = Data(base64Encoded: self) { // , options: .ignoreUnknownCharacters
//            for encoding in encodingsToTry {
//                if let str = String(data: data, encoding: encoding) {
//                    return str
//                }
//            }
//        }
        
        throw MNError(.misc_failed_decoding, reason: "String.fromBase64 does not seem to be encoded in base64 with any of \(encodingsToTry.descriptionsJoined). Is is escaped or percent encoded?")
    }
    
    
    /// Will try to convert the string back from base64 into a string, trying first utf16 encoding, and as a fallback utf8 encoding. If both methods fail, will return nil
    /// - Returns: Original string before it was converted to base 64, or nil if attempts at decoding in utf8 AND utf16 fails.
    func fromBase64() -> String? {
        do {
            return try self.fromBase64Throws()
        } catch let error {
            dlog?.notice("String.fromBase64() failed decoding: \(error.description)")
            return nil
        }
    }
    
    
    /// Returns a base-64 encoded string of the source string (utf-8)
    /// - Returns: the base-64 string representing the original string
    func toBase64() -> String {
        return self.data(using: .utf8)!.base64EncodedString()
    }
}

public extension String /* protobuf */ {
    
    func toProtobuf() -> String {
        dlog?.warning(".toProtobuf() IMPLEMENT PROTOBUF! ")
        return self
    }
    
    func fromProtobufThrows() throws -> String {
        dlog?.warning(".fromProtobuf() IMPLEMENT PROTOBUF!")
        
        return self
    }
    
    func fromProtobuf() -> String? {
        dlog?.warning(".fromProtobuf() IMPLEMENT PROTOBUF!")
        do {
            let str : String = try self.fromProtobufThrows()
            return str
        } catch let error {
            dlog?.warning(".fromProtobuf() Threw error:\(String(describing: error))")
        }
        return nil
    }
}
