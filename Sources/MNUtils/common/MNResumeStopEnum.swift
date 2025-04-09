//
//  MNResumeStopEnum.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import MNUtils
import MNMacros

public typealias MNFlowResult<Value> = FlowResult<Value, MNError>
public typealias MNEmptyFlowResult = FlowResult<Void, MNError>

// DO NOT: @SimplifiedEnum
public enum FlowResult<Value, Err> : CustomStringConvertible where Err : Error { // where Value : Hashable,
    
    /// A success, storing the `Value` value.
    case resume(Value?)
    
    /// A stop flow instruction, storing the `Value` value and an optional Error value
    case stop(Value?, Err? = nil)
    
    public enum Simplified : Codable, CaseIterable, Hashable {
        case resume
        case resumeEmpty
        case stopEmpty
        case stopWithError
        case stopWithValue
        case stopWithValueAndError
        var isStop : Bool {
            return self != .resume
        }
        var isResume : Bool {
            return self == .resume
        }
    }
    
    var simplified : Simplified {
        switch self {
        case .resume(let value):
            return (value == nil) ? .resumeEmpty : .resume
            
        case .stop(let value, let err):
            switch (value, err) {
            case (let value, let err):
                return .stopWithValueAndError
            case (let value, nil):
                return .stopWithValue
            case (nil, let err):
                return .stopWithError
            case (nil, nil):
                return .stopEmpty
            }
        }
    }
    
    public static func stopWithError(_ error:Err)->Self {
        return .stop(nil, error)
    }
    
    public static func stopWithValue(_ value:Value)->Self {
        return .stop(value, nil)
    }
    
    public static var stopEmpty : Self {
        return Self.stop(nil, nil)
    }
    
    public static var resumeEmpty : Self {
        return Self.resume(nil)
    }
    
    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .resume(let value):
            if value == nil {
                return ".resume(=empty=)"
            } else {
                return ".resume(value: \(String(describing:value))"
            }
        case .stop(let value, let err):
            switch (value, err) {
            case (let value, let err):
                return "stop(value: \(String(describing:value)), error: \(err?.description))"
            case (let value, nil):
                return "stop(value: \(String(describing:value)))"
            case (nil, let err):
                return "stop(error: \(err?.description))"
            case (nil, nil):
                return "stop(=empty=)"
            }
        }
    }
    
    public var isResume : Bool {
        switch self {
        case .resume:
            return true
        default:
            return false
        }
    }
    
    public var isResumeEmpty : Bool {
        switch self {
        case .resume(let val):
            return val != nil
        default:
            return false
        }
    }
    
    public var isStop : Bool {
        switch self {
        case .resume:
            return false
        default:
            return true
        }
    }
    
    public var isStoppedEmpty : Bool {
        switch self {
        case .resume:
            return false
        case .stop(let value, let error):
            return error == nil || value == nil
        }
    }
    
    public var value : Value? {
        switch self {
        case .resume(let value):
            return value
        case .stop(let value, let err):
            return value
        }
    }
    
    public var error : Err? {
        switch self {
        case .resume:
            return nil
        case .stop(_, let error):
            return error
        }
    }
    
     
    /// Convenence method to help convert values between one kind of FlowResult to another (i.e different generic Value types)
    /// - Parameter transform: block that recieves the FlowResult Value and returns a new FlowResult with a different generic Value type.
    /// - Returns: new FlowResult with a different Value type.
    public func transformingValue<NewValueType>(_ transform: (_ value:Value?)->NewValueType?)->FlowResult<NewValueType, Err> {
        switch self {
        case .resume(let value):
            return .resume(transform(value))
        case .stop(let value, let err):
            let val : NewValueType? = value != nil ? transform(value!) : nil
            return .stop(val, err)
            
        }
    }
    
    public func asEmptyResult() -> MNEmptyFlowResult {
        switch self {
        case .resume(let value):
            return .resumeEmpty
        case .stop(let value, let err):
            return .stop(nil, err as? MNError)

        }
    }
}

/*
@available(*, deprecated, renamed: "MNFlowResult", message: "MNResumeStopEnum was renamed MNFlowResult<Value, Err>")
public enum MNResumeStopEnum : Int {
    case resume = 1
    case stop = 256
    
    var isStop : Bool {
        return self == .stop
    }
    
    var isResume : Bool {
        return self == .stop
    }
}

@available(*, deprecated, renamed: "MNResumeStopTuple", message: "MNResumeStopEnum was renamed MNFlowResult<Value, Err>")
public struct MNResumeStopTuple<T:Any> {
    public typealias ValueType = T

    private(set) var instruction : MNResumeStopEnum = .resume
    public let value : T?
    
    public var valueType : Any.Type {
        return T.self
    }
    
    public var isResume : Bool {
        return instruction.isResume
    }

    public var isStop : Bool {
        return instruction.isStop
    }

    public static func resume(_ value : T? = nil) -> MNResumeStopTuple<T> {
        return MNResumeStopTuple(instruction: .resume, value: value)
    }
    
    public static func stop(_ value : T? = nil) -> MNResumeStopTuple<T> {
        return MNResumeStopTuple(instruction: .stop, value: value)
    }
    
    public static var stopEmpty : MNResumeStopTuple {
        return MNResumeStopTuple(instruction: .stop, value: nil)
    }
    
    public static var resumeEmpty : MNResumeStopTuple {
        return MNResumeStopTuple(instruction: .resume, value: nil)
    }
    
    mutating func stopTest(_ block:(_ curValue:T?)->Bool) {
        if block(value) {
            self.instruction = .stop
        } else {
            self.instruction = .resume
        }
    }
    
    mutating func resumeTest(_ block:(_ curValue:T?)->Bool) {
        if block(value) {
            self.instruction = .resume
        } else {
            self.instruction = .stop
        }
    }
    
    public var instrutionIsStop : Bool {
        return instruction.isStop
    }
    
    public var instrutionIsResume : Bool {
        return instruction.isResume
    }
    
    public mutating func changeToStop() {
        self.instruction = .stop
    }
    
    public mutating func changeToResume() {
        self.instruction = .resume
    }
}
*/
