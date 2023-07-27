//
//  MNPermission.swift
//  
//
//  Created by Ido on 06/12/2022.
//

import Foundation
import DSLogger
fileprivate let dlog : MNLogger? = MNLog.forClass("MNPermission")


public typealias MNAllowed = Hashable
public typealias MNForbidden = Hashable

public protocol MNPermissionable : Hashable, Equatable {
    associatedtype Allowed : MNAllowed
    associatedtype Forbidden : MNForbidden
    
    var isAllowed : Bool { get }
    var isForbidden : Bool { get }
    var allowedValue : Allowed? { get }
    var forbiddenValue : Forbidden? { get }
}

// MARK: Codable
fileprivate enum CodingKeys: String, CodingKey, CaseIterable {
    case allowed = "allowed"
    case forbidden = "forbidden"
    case undetermined = "undetermined"
}

@frozen public enum MNPermission<Allowed : MNAllowed, Forbidden: MNForbidden> : MNPermissionable where Forbidden : Error {
    /// A success, storing a `Success` value.
    case allowed(Allowed)
    
    /// A failure, storing a `Failure` value.
    case forbidden(Forbidden)
    
    public var isAllowed : Bool {
        switch self {
        case .allowed:    return true
        case .forbidden:  return false
        }
    }
    
    public var isForbidden : Bool {
        return !self.isAllowed
    }
    
    public var allowedValue : Allowed? {
        switch self {
        case .allowed(let success): return success
        case .forbidden:  return nil
        }
    }
    
    public var forbiddenValue : Forbidden? {
        switch self {
        case .allowed: return nil
        case .forbidden(let forbidden): return forbidden
        }
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .allowed(let allow):    hasher.combine(allow)
        case .forbidden(let forbid): hasher.combine(forbid)
        }
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNPermission, rhs:MNPermission)->Bool {
        guard lhs.isAllowed == rhs.isAllowed else {
            return false
        }
        if lhs.isForbidden && lhs.forbiddenValue == rhs.forbiddenValue {
            return true
        } else if lhs.isAllowed && lhs.allowedValue == rhs.allowedValue {
            return true
        }
        
        return false
    }
}

// MARK: Codable
extension MNPermission : Codable where Forbidden : Codable, Allowed : Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let allowed = try container.decodeIfPresent(Allowed.self, forKey: .allowed) {
            self = .allowed(allowed)
        } else if let forbidden = try container.decodeIfPresent(Forbidden.self, forKey: .forbidden) {
            self = .forbidden(forbidden)
        }
        
        throw MNError(.misc_failed_decoding, reason: "\(Self.self) failed decoding (no allowed AND no forbidden).")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(allowedValue, forKey: .allowed)
        try container.encodeIfPresent(forbiddenValue, forKey: .forbidden)
    }
}

extension MNPermission where Forbidden : Error {
    /// If the permission is a failure, throws the failure value (Error), or does nothing if permission isAllowed
    /// - Returns: void or throws if there is not permission
    public func throwIfForbidden() throws {
        if let err = self.forbiddenValue {
            throw err
        }
    }
}
