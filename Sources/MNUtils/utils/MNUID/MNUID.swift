//
//  MNUID.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNUID")?.setting(verbose: false)
#if DEBUG
fileprivate let IS_DEBUG = true
#else
fileprivate let IS_DEBUG = false
#endif

// MNUID is a wrapper for UUID(version 5) and type string, wrapping a v4 UUID as the namespace
// Using UUID v5 we can also embed the checksum of the type and namespace if we are the ones creating the UUID.
// Using UUID v5 we can also validate the checksum of the type and namespace if we recieved the UUID as a string from remote sources.
// reference:  https://www.rfc-editor.org/rfc/rfc4122
open class MNUID : MNUIDProtocol, LosslessStringConvertible, Comparable, Codable {
    
    // Seperator
    public static let SEPARATOR : String = "|"
    public static let NO_TYPE : String = "?"
    
    // Native iOS UUID is a RFC 4122 version 5 UUID:.
    private var _uid : UUIDv5
    open var uid : UUIDv5 {
        return _uid
    }
    
    open var type : String {
        dlog?.warning("\(Swift.type(of: self)) subclass of MNUID must override .type getter!")
        return Self.NO_TYPE
    }
    
    open func setType(str:String? = MNUID.NO_TYPE) {
        // Does nothing
        // Future subclasses might override setType and store the value
        dlog?.warning("\(Swift.type(of: self)) subclass of MNUID must override .setType()")
    }
    
    open func setType(type:LosslessStringConvertible) {
        self.setType(str: type.description)
    }
    
    public var uuidString: String {
        return "\(type)\(Self.SEPARATOR)\(uid.uuidString)"
    }
    
    // MARK: Equatable
    public static func == (lhs: MNUID, rhs: MNUID) -> Bool {
        return lhs.type == rhs.type && lhs.uid == rhs.uid
    }
    
    // MARK: Comperable
    // for sorting UIDs by type, then by UUID hash value
    public static func < (lhs: MNUID, rhs: MNUID) -> Bool {
        return lhs.type < rhs.type && lhs.uid.hashValue == rhs.uid.hashValue
    }
    
    // MARK: LosslessStringConvertible
    required convenience public init?(_ description: String) {
        let components = description.components(separatedBy: Self.SEPARATOR)
        guard description.count > 12 && components.count < 2 else {
            // Bad string size or comps
            dlog?.warning("\(Self.self).init (LosslessStringConvertible) failed with too few components!")
            return nil
        }

        // This has some kind of redundency that even if no type, we still get the uuid
        var type = Self.NO_TYPE
        if components.count > 1 {
            type = Array(components.prefix(components.count - 1)).joined();
        }
        
        if type.count > 0,
            let uidString = components.last
        {
            do {
                let uid = try UUID(version: .v5, name: type, nameSpace: .custom(uidString))
                // Call init
                self.init(uid:uid, typeStr: type)
            } catch let error {
                dlog?.warning("\(Self.self).init (LosslessStringConvertible) [\(description)] did not contain a MNUIDType or type string. \(error.description)")
                return nil
            }
            
            if IS_DEBUG && type == Self.NO_TYPE {
                dlog?.warning("\(Self.self).init (LosslessStringConvertible) [\(description)] did not contain a MNUIDType or type string.")
            }
        } else {
            dlog?.warning("\(Self.self).init (LosslessStringConvertible) failed: [\(description)] could not be used to init.")
            return nil
        }
    }
    
    // MARK: StringConvertible
    public var description: String {
        return uuidString
    }
    
    // MARK: Default initializers:
    public required init(typeStr:String = MNUID.NO_TYPE ) {
        do {
            self._uid = try UUIDv5(version: .v5, name: typeStr, nameSpace: .uuidV4)
        } catch let error {
            dlog?.warning("TUID.init(type:String) failed: \(error.description)")
            self._uid = UUID();
        }
        self.setType(str:type)
    }

    public required init(uid auid: UUID, typeStr atype:String = MNUID.NO_TYPE) {
        switch auid.version {
        case .v5:
            // We re-use all components
            self._uid = auid
            self.setType(str: atype)
            break;
        case .v4:
            do {
                self._uid = try UUID(version: .v5, name: atype, nameSpace: .custom(auid.uuidString));
            } catch let error {
                dlog?.warning("TUID.init(uid:type) failed creating UUID: \(error.description)")
                self._uid = UUID();
            }
            self.setType(str: atype);
            break;
        default:
            self._uid = UUID(uuidString: UID_EMPTY_STRING)!;
            break;
        }
        
        if IS_DEBUG && !self._uid.isValid(name: atype) {
            dlog?.warning("TUID.init(uid:type) auid hashed type does not match the provided type: \(atype)")
            return
        }
    }

    public convenience init?(uuidString: String, typeStr:String? = nil) {
        guard let auid = UUID(uuidString: uuidString) else {
            dlog?.warning("failed using uuidString: \(uuidString) to create a UUID instance!")
            return nil
        }
        self.init(uid:auid, typeStr:typeStr ?? MNUID.NO_TYPE)
    }
    
    public var isEmpty : Bool {
        return self.uid.uuidString == UID_EMPTY_STRING || self.type.count == 0
    }
}

