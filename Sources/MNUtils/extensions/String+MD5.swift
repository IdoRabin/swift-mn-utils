//
//  String+MD5.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import CommonCrypto

extension String /* MD5 */ {
    
    /// Returns a MD5 of a given string to a given length. Not cryptographically secure.
    /// NOTE: Not for use in security or cryptographically importans impliementations.
    /// - Parameters:
    ///   - string: string to get the MD5 for
    ///   - length: the required resulting length of the MD5 checksum
    /// - Returns: the MD5 for the original string
    static func MD5NotSecure(string: String, length:Int = 0) -> Data {
        let length = (abs(length) > 8) ? abs(length) : Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        // NOTE: DEPRECATED: is not using
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    (CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory))
                }
                return 0
            }
        }
        return digestData
    }
    
    static func MD5NotSecureString(string: String, length:Int = 0) -> String {
        return MD5NotSecure(string: string, length:length).base64EncodedString()
    }
    
    func toMD5NotSecure(length:Int = 0) -> String {
        return Self.MD5NotSecureString(string: self, length:length)
    }
}
