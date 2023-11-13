//
//  MNDBEnum.swift
//  
//
//  Created by Ido on 18/07/2023.
//

import Foundation

// The enum gets a "DB name"

/// Simplifies use of enums into DBs
/// NOTE: Remember that @Enum(...) fluent field wrapper!
/// NOTE: To be used with string-backed enums
public protocol MNDBEnum : JSONSerializable & Hashable & Equatable & CaseIterable {
    
    // db enum name is the name of this type/schema as a custom enum in the db..
    static var dbEnumName : String { get }
    var dbEnumName : String { get }
    
    // db case name is the name of a specific case fro use in the db
    var dbCaseName : String { get }
}

public extension MNDBEnum /* default implementation */{
    
    static var dbEnumName : String {
        MNDBUtils.mnDefaultDBTypeNameTransform("\(self)")
    }
    var dbEnumName : String { return Self.dbEnumName }
    
    var dbCaseName : String {
        var result = "\(self)"
        if let rawRep = self as? any RawRepresentable<String> {
            result = rawRep.rawValue
        }
        return result
    }
}

// Model helpers - allows changing the naming convention for table names and column names, enum or not.
open class MNDBUtils {
    public static var transformFixes : [String:String] = [
        "r_rabac_" : "rrabac_",
        "c_r_u_d_" : "crud_",
        "p_i_i_" : "pii_",
        "_m_n_" : "_mn_",
    ]
    public static func mnDefaultDBTypeNameTransform(_ name:String)->String {
        return name.camelCaseToSnakeCase().replacingOccurrences(ofFromTo:transformFixes)
    }
    
//  DEPRECATED  public static func mnDefaultDBEnumCaseNameTransform(_ name:String)->String {
//  DEPRECATED      return name.camelCaseToSnakeCase().replacingOccurrences(ofFromTo:transformFixes)
//  DEPRECATED  }
}
