//
//  ResultEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public extension Result {
    var isSuccess : Bool {
        switch self {
        case .success: return true
        case .failure: return false
        // default: return false
        }
    }
    var isFailed : Bool {
        return !self.isSuccess
    }
}

public extension Result where Failure : Error {
    
    var errorValue : Error? {
        switch self {
        case .success: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
    
    var successValue : Success? {
        switch self {
        case .success(let succ): return succ
        case .failure: return nil
        }
    }
}

