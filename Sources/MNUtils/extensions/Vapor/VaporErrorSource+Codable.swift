//
//  Error+Codable.swift
//  
//
//  Created by Ido on 16/11/2022.
//

import Foundation

#if VAPOR
import Vapor


extension ErrorSource : Codable {
    
    private enum CodingKeys: String, CodingKey {
        case file = "file"
        case function = "function"
        case line = "line"
        case column = "column"
        case range = "range"
        
        static var all : [CodingKeys] = [.file, .function, .line, .column, .range]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(file, forKey: .file)
        try container.encode(function, forKey: .function)
        try container.encode(line, forKey: .line)
        try container.encode(column, forKey: .column)
        if let rng = self.range {
            try container.encode(rng, forKey: .range)
        }
    }
    
    public init(from decoder: Decoder) throws {
        self.init(file: "", function: "", line: 0, column: 0)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decode(String.self, forKey: .file)
        function = try container.decode(String.self, forKey: .function)
        line = try container.decode(UInt.self, forKey: .line)
        column = try container.decode(UInt.self, forKey: .column)
        range = try container.decodeIfPresent(Range<UInt>.self, forKey: .range)
    }
}

#endif
