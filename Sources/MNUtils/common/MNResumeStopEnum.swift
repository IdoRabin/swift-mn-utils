//
//  MNResumeStopEnum.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

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

struct MNResumeStopTuple<T:Any> {
    typealias ValueType = T
    
    private (set) var instruction : MNResumeStopEnum = .resume
    let value : T?
    
    var valueType : Any.Type {
        return T.self
    }
    
    static func resume(_ value : T? = nil) -> MNResumeStopTuple<T> {
        return MNResumeStopTuple(instruction: .resume, value: value)
    }
    
    static func stop(_ value : T? = nil) -> MNResumeStopTuple<T> {
        return MNResumeStopTuple(instruction: .stop, value: value)
    }
    
    static var stopEmpty : MNResumeStopTuple {
        return MNResumeStopTuple(instruction: .stop, value: nil)
    }
    
    static var resumeEmpty : MNResumeStopTuple {
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
    
    var instrutionIsStop : Bool {
        return instruction.isStop
    }
    
    var instrutionIsResume : Bool {
        return instruction.isResume
    }
    
    mutating func changeToStop() {
        self.instruction = .stop
    }
    
    mutating func changeToResume() {
        self.instruction = .resume
    }
}
