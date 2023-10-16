//
//  MemotyAddress.swift
//  
//
//  Created by Ido on 25/09/2023.
//

import Foundation

public struct MemoryAddress<T>: CustomStringConvertible, Equatable, Hashable, RawRepresentable {
    public typealias RawValue = Int
    
    public var rawValue: Int

    //MARK: RawRepresentable
    public init?(rawValue: Int) {
        let msg = "MemoryAddress?(rawValue: Int) init of item should not be initialized with a raw Int! use: MemoryAddress(of:) instead!"
        preconditionFailure(msg)
        return nil
    }
    
    // MARK: CustomStringConvertible
    public var description: String {
        let length = 2 + 2 * MemoryLayout<UnsafeRawPointer>.size
        return String(format: "%0\(length)p", rawValue)
    }

    // for structures
    init(of structPointer: UnsafePointer<T>) {
        rawValue = Int(bitPattern: structPointer)
    }
}

public extension MemoryAddress where T: AnyObject {

    // for classes
    init(of classInstance: T) {
        rawValue = unsafeBitCast(classInstance, to: Int.self)
        // or
        // Int(bitPattern: Unmanaged<T>.passUnretained(classInstance).toOpaque())
    }
}


/*
public extension String {
    
    init (memoryAddressOf object:AnyObject) {
        self.init(MemoryAddress(of: object).description)
    }
    
    init (memoryAddressOfOrNil object:AnyObject?) {
        guard let object = object else {
            self.init("<nil>")
            return
        }
        self.init(MemoryAddress(of: object).description)
    }
    
    
    /// Returns a string describing the memory address of the struct. The struct must be in an mutable state, because this is an inout call
    init<T>(memoryAddressOfStruct structPointer: UnsafePointer<T>) {
        self.init(MemoryAddress(of: structPointer).description)
    }
}*/
