//
//  UUIDv5.swift
//  
//
//  Created by Ido on 11/10/2022.
//

import Foundation
import CommonCrypto
import DSLogger

public typealias UUIDv5 = UUID
public let UID_EMPTY_STRING : String = "00000000-0000-0000-0000-000000000000";

fileprivate let dlog : DSLogger? = DLog.forClass("UUIDv5")

public extension UUID {
    static var UUID_EMPTY_STRING : String {
        return UID_EMPTY_STRING
    }
    
    enum UUIDVariant: Hashable {
        /// A variant reserved for NCS backward compatibility.
        case reservedNCS
        /// The variant specified in specified in [RFC 4122](https://tools.ietf.org/html/rfc4122).
        case rfc4122
        /// A variant reserved for Microsoft backward compatibility.
        case reservedMicrosoft
        /// A variant reserved for for future definition.
        case reservedFuture
    }
    

    enum UUIDVersion: Int {
        case v3 = 3
        case v4 = 4
        case v5 = 5
    }

    enum UUIDv5Namespace {
        case dns
        case url
        case oid
        case x500
        case uuidV4
        case custom(String)
        
        var rawValue : String {
            return self.value;
        }
        
        var value : String {
            var result = "Unknown";
            switch self {
            case .dns:   result = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
            case .url:   result = "6ba7b811-9dad-11d1-80b4-00c04fd430c8";
            case .oid:   result = "6ba7b812-9dad-11d1-80b4-00c04fd430c8";
            case .x500:  result = "6ba7b814-9dad-11d1-80b4-00c04fd430c8";
            case .uuidV4: result = UUID().uuidString; // Create a random UUIDv4 on the spot.
            case .custom(let str): result = str;
            }
            return result;
        }
        
        public enum Simplified : Equatable {
            case dns
            case url
            case oid
            case x500
            case uuidV4
            case custom
            
            static var all : [Simplified] = [.dns, .url, .oid, .x500, .uuidV4, .custom]
        }
        
        var simplified : Simplified {
            switch self {
            case .dns:   return .dns;
            case .url:   return .url;
            case .oid:   return .oid;
            case .x500:  return .x500;
            case .uuidV4:  return .uuidV4;
            case .custom: return .custom;
            }
        }
        
        static var allSimplified : [Simplified] = [.dns, .url, .oid, .x500, .uuidV4, .custom]
        static var all : [UUIDv5Namespace] = [.dns, .url, .oid, .x500, .uuidV4, .custom("?")]
    }

    func isValid(name:String, nameSpace: UUIDv5Namespace = .uuidV4)->Bool {
        // Validate UUID version nr:
        guard self.version == .v5 else {
            return false
        }
        
        // Validate the "name" string was hashed into the UID v5 with the namespace:
        guard self.validateV5Hashed(name:name, nameSpace: nameSpace) else {
            return false
        }
        
        // Valid
        return true;
    }
    
    init(version: UUIDVersion, name: String, nameSpace: UUIDv5Namespace) throws {
        // Get UUID bytes from name space:
        var spaceUID = UUIDv5(uuidString: nameSpace.value.uppercased())!.uuid
        var data = withUnsafePointer(to: &spaceUID) { [count =  MemoryLayout.size(ofValue: spaceUID)] in
            Data(bytes: $0, count: count)
        }

        // Append name string in UTF-8 encoding:
        data.append(contentsOf: name.uppercased().utf8)

        // Compute digest (MD5 or SHA1, depending on the version):
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH)) // CC_SHA1_DIGEST_LENGTH in CommonCryprt
        try data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) throws -> Void in
            switch version {
            case .v3:
                // CC_MD5' was deprecated in macOS 10.15: This function is cryptographically broken and should not be used in security contexts. Clients should migrate to SHA256 (or stronger).
                // We keep this for BKWD compatibility:
                // DEPRECATED: _ = CC_MD5(ptr.baseAddress, CC_LONG(data.count), &digest)
                throw MNError(MNErrorCode.misc_failed_crypto, reason: "CC_MD5' was deprecated in macOS 10.15: This function is cryptographically broken and should not be used in security contexts. Clients should migrate to UID v5 (or v4) SHA256 (or stronger).")
            case .v4:
                // Does nothing - native NSUUID is UUID v4 compliant. (see RFC 4122 versions for more detail)
                break;
            case .v5:
                _ = CC_SHA1(ptr.baseAddress, CC_LONG(data.count), &digest)
            }
        }

        // Set version bits:
        digest[6] &= 0x0F
        digest[6] |= UInt8(version.rawValue) << 4
        // Set variant bits:
        digest[8] &= 0x3F
        digest[8] |= 0x80

        // Create UUID from digest:
        // native NSUUID is UUID v4 compliant. (see RFC 4122 versions for more detail)
        self = NSUUID(uuidBytes: digest) as UUIDv5
    }
    
    private func validateV5Hashed(name:String, nameSpace: UUIDv5Namespace = .uuidV4)->Bool {
        // Validate the "name" string was hashed into the UID v5 with the namespace:
        var result : Bool = false
        
        // We need to find if name was encrypted into the UUID:
        // V5 can be validated ONLY if one hase
        if nameSpace.simplified == .uuidV4  {
            
            // If UUIDv5Namespace is uuidV4 we cannot validate UNLESS we have the original v4 UUID.
            result = true
            
        } else {
            do {
                let newUUID = try UUID(version: .v5, name: name, nameSpace: nameSpace)
                
                // This validation assumes the name and namespace are the same as when creating the existing v5 UUID:
                result = (newUUID == self)
                
            } catch let error {
                dlog?.note(".validateV5Hashed Faild validating by creating a new UUID error:\(error.description)")
            }
        }
        
        return result;
    }
    
    var variant: UUIDVariant {
        switch uuid.8 {
        case 0x80 ... 0xbf:
            return .rfc4122
        case 0xc0 ... 0xdf:
            return .reservedMicrosoft
        case 0xe0 ... 0xff:
            return .reservedFuture
        default:
            return .reservedNCS
        }
    }
    
    
    /// The version number of the UUID.
    ///
    /// This property is `nil` when `variant` is not equal to `.rfc4122`.
    ///
    /// [RFC4122](https://tools.ietf.org/html/rfc4122) defines the following versions:
    /// - `1`: Time-based UUID.
    /// - `2`: DCE Security UUID.
    /// - `3`: Name-based UUID using MD5 hashing.
    /// - `4`: Random UUID.
    /// - `5`: Name-based UUID using SHA-1 hashing.
    var version : UUIDVersion? {
        var result : UUIDVersion? = nil
        switch self.variant {
        case .rfc4122:
            result = UUIDVersion.init(rawValue: Int(self.uuid.6 >> 4))
        default:
            result = nil
        }
        
        return result;
    }
}
