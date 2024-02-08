//
//  AppErrorCodable.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public protocol MNErrorCodable : MNErrorable, Codable, JSONSerializable {
    // Just allows encoding / decoding of an Error
}

public extension MNErrorCodable /* default implementation */ {
    /// CustomStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    var description: String { // CustomStringConvertible
        var res : String = self.serializeToJsonString(prettyPrint: false) ?? ""
        if (res.count == 0) {
            // Convert to string failed:
            // Minimal response:
            res = self.domainCodeDesc + " | " + (self.reason);
        }
        return res.replacingOccurrences(ofFromTo: ["\"" : "'"], caseSensitive: true)
    }

}
