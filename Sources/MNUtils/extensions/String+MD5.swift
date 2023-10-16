//
//  String+MD5.swift
//  
//
//  Created by Ido on 27/08/2023.
//

import Foundation
import CommonCrypto

extension String /* MD5 */ {
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
