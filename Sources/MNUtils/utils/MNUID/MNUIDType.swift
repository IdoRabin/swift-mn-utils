//
//  MNUIDType.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNUIDTypes")

// Instead of an Enum, we use this, which is extendable:
public struct MNUIDType: RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    init(_ value: String) { self.rawValue = value }
    public init?(rawValue: String) { self.init(rawValue) }
    public init(stringLiteral value: String) { self.init(value) }
    public init(unicodeScalarLiteral value: String) { self.init(value) }
    public init(extendedGraphemeClusterLiteral value: String) { self.init(value) }
    
    // "Cases"
    public static let person : MNUIDType       = "PER"
    public static let company : MNUIDType      = "COM"
    public static let user : MNUIDType         = "USR"
}

public extension MNUID {
    convenience init(type:MNUIDType = MNUIDType.person) {
        self.init(typeStr: type.rawValue)
    }

    convenience init(uid auid: UUID, type:MNUIDType) {
        self.init(uid:auid, typeStr:type.rawValue)
    }
    
    convenience init?(uuidString: String, type buidType:MNUIDType) {
        guard let auid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(uid:auid, typeStr:buidType.rawValue)
    }
}

public class PersonUID : MNUID {
    override public var type : String { return MNUIDType.person.rawValue }
    override public func setType(str:String? = MNUIDType.person.rawValue) {/* does nothing ; */}
}

public class CompanyUID : MNUID {
    override public var type : String { return MNUIDType.company.rawValue }
    override public func setType(str:String? = MNUIDType.company.rawValue) {/* does nothing ; */}
}

public class UserUID : MNUID {
    override public var type : String { return MNUIDType.user.rawValue }
    override public func setType(str:String? = MNUIDType.user.rawValue) {/* does nothing ; */}
}
