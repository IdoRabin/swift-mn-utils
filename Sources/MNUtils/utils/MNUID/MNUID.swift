//
//  MNUID.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNUID") // ?.setting(verbose: false)
#if DEBUG
fileprivate let IS_DEBUG = true
#else
fileprivate let IS_DEBUG = false
#endif

// MNUID is a wrapper for UUID(version 5 capable) which also contains a "type" string, wrapping a v4 UUID as the namespace
// The "type" string allows indicating in real time the "type" of the owning instance, mainly for Debugging / Validation purposes
// Using UUID v5 we can also embed the checksum of the type and namespace if we are the ones creating the UUID.
// Using UUID v5 we can also validate the checksum of the type and namespace if we recieved the UUID as a string from remote sources.
// reference:  https://www.rfc-editor.org/rfc/rfc4122
open class MNUID : MNUIDProtocol, LosslessStringConvertible, Comparable, Codable {
    
    // Seperator
    public static let SEPARATOR : String = "|"
    public static let NO_TYPE : String = "?"
    public static let DEFAULT_TYPE = NO_TYPE
    
    // Native iOS UUID is a RFC 4122 version 5 UUID:.
    private var _uid : UUIDv5
    open var uid : UUIDv5 {
        return _uid
    }
    
    private var _type : String = MNUID.DEFAULT_TYPE
    open var type : String {
        return _type
    }
    private func setTypeOnInit(str:String?) {
        guard let str = str, str.count > 0 else {
            self._type = Self.DEFAULT_TYPE
            return
        }
        self._type = str
    }
    
    open func setType(str:String?) {
        guard let newValue = str, newValue.count > 0 else {
            self._type = Self.DEFAULT_TYPE
            return
        }

        if newValue != self._type {
            dlog?.notice("Setting type from: [\(self._type)] to [\(newValue)]")
            self._type = newValue
        }
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
    required convenience public init?(_ description: String, logFailure:Bool = false) {
        let ddlog = (logFailure && dlog != nil) ? dlog : nil
        let components = description.components(separatedBy: Self.SEPARATOR)
        guard description.count > 12 && components.count < 2 else {
            // Bad string size or comps
            ddlog?.warning("\(Self.self).init (LosslessStringConvertible) failed with too few components!")
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
                ddlog?.warning("\(Self.self).init (LosslessStringConvertible) [\(description)] did not contain a MNUIDType or type string. \(error.description)")
                return nil
            }
            
            if IS_DEBUG && type == Self.NO_TYPE {
                ddlog?.warning("\(Self.self).init (LosslessStringConvertible) [\(description)] did not contain a MNUIDType or type string.")
            }
        } else {
            ddlog?.warning("\(Self.self).init (LosslessStringConvertible) failed: [\(description)] could not be used to init.")
            return nil
        }
    }
    
    required convenience public init?(_ description: String) {
        self.init(description, logFailure: true)
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
            dlog?.warning("\(Self.self).init(type:String) failed: \(error.description)")
            self._uid = UUIDv5()
        }
        self.setTypeOnInit(str: typeStr)
    }

    public required init(uid auid: UUID, typeStr atype:String = MNUID.NO_TYPE) {
        
        switch auid.version {
        case .v5:
            // We re-use all components
            self._uid = auid
        case .v4:
            do {
                self._uid = try UUID(version: .v5, name: atype, nameSpace: .custom(auid.uuidString));
            } catch let error {
                dlog?.warning("\(Self.self).init(uid:type) failed creating UUID: \(error.description)")
                self._uid = UUIDv5();
            }
        default:
            self._uid = UUID(uuidString: UID_EMPTY_STRING)!;
        }
        
        self.setTypeOnInit(str: atype)
        
        if IS_DEBUG && !self._uid.isValid(name: atype, nameSpace: .uuidV4) {
            dlog?.warning("\(Self.self)..init(uid:type) auid hashed type does not match the provided type: \(atype)")
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

