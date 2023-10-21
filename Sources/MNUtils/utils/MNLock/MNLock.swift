//
//  MNLock.swift
//  
//
//  Created by Ido on 03/08/2023.
//

import Foundation

#if canImport(Vapor)
import Vapor
import NIOConcurrencyHelpers
#endif

public protocol BasicLockProtocol {
    func lock()
    func unlock()
}

public protocol LockProtocol : BasicLockProtocol {
    
    @inlinable
    func withLock<ReturnValue>(_ body: @escaping  () throws -> ReturnValue) rethrows -> ReturnValue
    
    @inlinable
    func withAsyncLock<ReturnValue>(_ body: @escaping  () async throws -> ReturnValue) async rethrows -> ReturnValue
    
    @inlinable
    func withLockVoid(_ body: @escaping  () throws -> Void) rethrows -> Void
}

public final class MNLock : CustomDebugStringConvertible {
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    public let mLock: LockProtocol
    private (set) public var name : String
    
    // MARK: Private
    
    // MARK: Lifecycle
    public init(name:String) {
        self.name = name
        #if canImport(Vapor)
            if let vaporLock = Environment.get("VAPOR_LOCK")?.lowercased(), vaporLock == "true" {
                mLock = NIOLock()
                // print("Using NIOLock")
            } else {
                mLock = NSLock()
                //print("Using NSLock")
            }
        #else
        mLock = NSLock()
            // print("Using NSLock")
        #endif
    }
    
    // MARK: Public
    public func changeName(to newName:String) {
        name = newName
    }
    
    // MARK: CustomDebugStringConvertible
    public var debugDescription: String {
        return "<MNLock.\(name)>"
    }
    
    // MARK: LockProtocol
    @inlinable
    public func withLock<ReturnValue>(_ body: @escaping () throws -> ReturnValue) rethrows -> ReturnValue {
        try mLock.withLock(body)
    }
    
    @inlinable
    public func withAsyncLock<ReturnValue>(_ body: @escaping () async throws -> ReturnValue) async rethrows -> ReturnValue {
        try await mLock.withAsyncLock(body)
    }
    
    @inlinable
    public func withLockVoid(_ body: @escaping () throws -> Void) rethrows -> Void {
        try mLock.withLockVoid(body)
    }
    
    @inlinable
    func lock() {
        mLock.lock()
    }
    
    @inlinable
    func unlock() {
        mLock.unlock()
    }
}

// Extend NSLock to conform to LockProtocol
extension NSLock: LockProtocol {
    @inlinable
    public func withLock<ReturnValue>(_ body: @escaping () throws -> ReturnValue) rethrows -> ReturnValue {
        lock()
        defer { unlock() }
        return try body()
    }
    
    @inlinable
    public func withAsyncLock<ReturnValue>(_ body: @escaping () async throws -> ReturnValue) async rethrows -> ReturnValue {
        lock()
        defer { unlock() }
        return try await body()
    }
    
    @inlinable
    public func withLockVoid(_ body: @escaping () throws -> Void) rethrows -> Void {
        lock()
        defer { unlock() }
        try body()
    }
}
