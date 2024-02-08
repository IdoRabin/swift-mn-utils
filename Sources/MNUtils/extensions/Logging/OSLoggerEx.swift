//
//  OSLoggerEx.swift
//
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
/*
import os

// Extension for os.Logger (internal package in apple os products)
public extension os.Logger {
    
    var isVerboseActive : Bool {
        return false
    }
    
    func todo(level: OSLogType = .debug, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.todo.rawValue) \(msg)")
    }
                 
    func verbose(symbol: MNLogSymbol = .info, _ msg: String) {
        guard isVerboseActive else {
            return
        }
        self.log("\(symbol.rawValue) \(msg)")
    }
    
    func note(level: OSLogType = .error, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.note.rawValue) \(msg)")
    }
  
    func success(level: OSLogType = .info, _ msg: String) {
        self.log(level: level, "\(MNLogSymbol.success.rawValue) \(msg)")
    }
    
    func fail(level: OSLogType = .info, _ msg: String) {
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
*/
