//
//  MNResult3.swift
//  
//
//  Created by Ido on 19/03/2023.
//

import Foundation

public typealias MNResult<Success:Any> = Result<Success, MNError>
public typealias MNResultBlock<Success:Any> = (MNResult<Success>)->Void

func MNResultOrErr<Success:Any>(_ result:Success?, error:MNError)->MNResult<Success> {
    if let result = result {
        return MNResult.success(result)
    } else {
        return MNResult.failure(error)
    }
}

extension Result {
    
    static func failure<Success:Any>(fromError error:Error)->MNResult<Success> {
        if let mnerror = error as? MNError {
            return MNResult.failure(mnerror)
        } else {
            return MNResult.failure(MNError(error: error))
        }
        
    }
    
    static func failure<Success:Any>(fromAppError mnError:MNError)->MNResult<Success> {
        return MNResult.failure(mnError)
    }
    
    static func failure<Success:Any>(code mnErrorCode:MNErrorCode, reason:String? = nil)->MNResult<Success> {
        return MNResult.failure(MNError(code:mnErrorCode, reason: reason))
    }
    
    static func failure<Success:Any>(code mnErrorCode:MNErrorCode, reasons:[String]? = nil)->MNResult<Success> {
        return MNResult.failure(MNError(code:mnErrorCode, reasons: reasons))
    }
    
    static func fromError<Success:Any>(_ error:Error?, orSuccess:Success)->MNResult<Success> {
        if let mnError = error as? MNError {
            return Self.fromMNError(mnError, orSuccess: orSuccess)
        } else if let err = error {
            return Self.fromMNError(MNError(error: err), orSuccess: orSuccess)
        } else {
            return .success(orSuccess)
        }
    }
    
    static func fromMNError<Success:Any>(_ mnError:MNError?, orSuccess:Success)->MNResult<Success> {
        if let mnError = mnError {
            return .failure(mnError)
        } else {
            return .success(orSuccess)
        }
    }
}

// Description for CustomStringConvertibles
extension Result where Success : CustomStringConvertible, Failure : CustomStringConvertible {
    var description : String {
        switch self {
        case .success(let success):
            return ".success(\(success.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        case .failure(let err):
            return ".failure(\(err.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        }
    }
}
