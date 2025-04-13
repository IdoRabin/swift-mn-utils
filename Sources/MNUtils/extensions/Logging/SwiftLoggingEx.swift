//
//  SwiftLoggingEx.swift
//
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
// Extensing swift-log package from SPM
// see .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),

import Logging

// extension os.Logger {

public extension Logging.Logger {
    typealias LogType = Logger.Level
    
    var isVerboseActive : Bool {
        return false
    }
    
    func todo(level: LogType = .debug, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.todo.rawValue) \(msg)")
    }
                 
    func verbose(symbol: MNLogSymbol = .info, _ msg: String) {
        guard isVerboseActive else {
            return
        }
        self.log(level: .info,"\(symbol.rawValue) \(msg)")
    }
    
    func note(level: LogType = .notice, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.note.rawValue) \(msg)")
    }
  
    func success(level: LogType = .info, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.success.rawValue) \(msg)")
    }
    
    func fail(level: LogType = .info, _ msg: String) {
        // ✗
        self.log(level: level, "\(MNLogSymbol.fail.rawValue) \(msg)")
    }
    
    func successOrFail(condition: Bool,
                              succStr: String,
                              failStr: String) {
        if condition {
            self.success(level: .info, succStr)
        } else {
            self.fail(level: .info, failStr)
        }
    }
    
    func successOrFail(condition: Bool,
                        _ bothCaseStr: String) {
        self.successOrFail(condition: condition, succStr: bothCaseStr, failStr: bothCaseStr)
    }
}

