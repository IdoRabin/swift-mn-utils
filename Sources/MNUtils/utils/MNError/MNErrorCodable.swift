//
//  AppErrorCodable.swift
//  
//
//  Created by Ido on 16/03/2023.
//

import Foundation

protocol MNErrorCodable : MNErrorable, Codable, JSONSerializable {
    // Just allows encoding / decoding of an Error
}

extension MNErrorCodable /* default implementation */ {
    /// CustomStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    public var description: String { // CustomStringConvertible
        var res : String = self.serializeToJsonString(prettyPrint: false) ?? ""
        if (res.count == 0) {
            // Convert to string failed:
            // Minimal response:
            res = self.domainCodeDesc + " | " + (self.reason);
        }
        return res.replacingOccurrences(ofFromTo: ["\"" : "'"], caseSensitive: true)
    }

}
