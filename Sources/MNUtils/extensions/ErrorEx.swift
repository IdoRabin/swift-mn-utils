//
//  ErrorEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public extension Error {
    
    var description : String {
            var result = "<unknown error \(type(of: self)) \(self.localizedDescription)>"
        
        // DO NOT USE SWITCH CASE
        // NOTE: Order of conditions matters here!
        if let apperror = self as? MNErrorable {
            result = apperror.description
        } else if type(of: self) == NSError.self {
            let nserror = self as NSError
            result = "\(nserror.domain):\(nserror.code)"
            let debugDes = nserror.debugDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !result.contains(debugDes) {
                result += " \(debugDes)."
            }
            if let str = nserror.localizedFailureReason {
                result += " \(str)."
            }
            if let str = nserror.localizedRecoveryOptions {
                result += " \(str)."
            }
            if let str = nserror.localizedRecoverySuggestion {
                result += " \(str)."
            }
            if !nserror.userInfo.isEmpty {
                result += "\n user info: \(nserror.userInfo)"
            }
            if #available(macOS 11.3, *) {
                for err in nserror.underlyingErrors {
                    result += "\n  underlying error: \(err.description)"
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            if MNUtils.debug.IS_DEBUG {
                result = String(describing: self)
            } else {
                result = self.localizedDescription
            }
            
        }
        
        return result
    }
    
}

public extension NSError {
    var reason : String {
        return self.localizedDescription // ?? self.localizedFailureReason ?? self.description
    }
}
