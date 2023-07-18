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
    
    // db name is the name of this type/schema as a custom enum in the db..
    static var dbName : String { get }
}

public extension MNDBEnum {
    static var dbName : String {
        MNDBUtils.mnDefaultDBTypeNameTransform("\(self)")
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
    
//    public static func mnDefaultDBEnumCaseNameTransform(_ name:String)->String {
//        return name.camelCaseToSnakeCase().replacingOccurrences(ofFromTo:transformFixes)
//    }
}
