//
//  MNResult3.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public typealias MNResult<Success:Any> = Result<Success, MNError>
public typealias MNResultBlock<Success:Any> = (MNResult<Success>)->Void

public func MNResultOrErr<Success:Any>(_ result:Success?, error:MNError)->MNResult<Success> {
    if let result = result {
        return MNResult.success(result)
    } else {
        return MNResult.failure(error)
    }
}

public extension MNResult {
    var mnErrorValue : MNError? {
        return self.errorValue as? MNError
    }
    
    var nsErrorValue : NSError? {
        return self.errorValue as? NSError
    }
}

public extension Result {
    
    // NOTE: Swift 6 will not allow using base Generic parameters in the extension claiming they "Shadow" the declared generic params. ):
    // TODO: Check how can reuse same Generic params when no 
    
    static func failure<ShadowSuccess>(fromError error:any Error)->MNResult<ShadowSuccess> {
        if let mnerror = error as? MNError {
            return MNResult.failure(mnerror)
        } else {
            return MNResult.failure(MNError(error: error))
        }
    }
    
    static func failure<ShadowSuccess>(fromAppError mnError:MNError)->MNResult<ShadowSuccess> {
        return MNResult.failure(mnError)
    }
    
    static func failure<ShadowSuccess>(code mnErrorCode:MNErrorCode, reason:String? = nil, underlyingError:Error? = nil)->MNResult<ShadowSuccess> {
        return MNResult.failure(MNError(code:mnErrorCode, reason: reason, underlyingError: underlyingError))
    }
    
    static func failure<ShadowSuccess>(code mnErrorCode:MNErrorCode, reason:String? = nil)->MNResult<ShadowSuccess> {
        return self.failure(code: mnErrorCode, reason: reason, underlyingError: nil)
    }
    
    static func failure<ShadowSuccess>(code mnErrorCode:MNErrorCode, reasons:[String]? = nil, underlyingError:Error? = nil)->MNResult<ShadowSuccess> {
        return MNResult.failure(MNError(code:mnErrorCode, reasons: reasons, underlyingError: underlyingError))
    }
    
    static func failure<ShadowSuccess>(code mnErrorCode:MNErrorCode, reasons:[String]? = nil)->MNResult<ShadowSuccess> {
        return self.failure(code: mnErrorCode, reasons: reasons, underlyingError: nil)
    }
    
    static func successOrFail<ShadowSuccess>(usingOther other:Self, convert:(_ success:Success)->ShadowSuccess)->MNResult<ShadowSuccess> {
        switch other {
        case .success(let succ):
            return MNResult<ShadowSuccess>.success(convert(succ))
            
        case .failure(let fail):
            return Self.failure(fromError: fail)
            
        }
//        if let mnError = error as? MNError {
//            return Self.fromMNError(mnError, orSuccess: orSuccess)
//        } else if let err = error {
//            return Self.fromMNError(MNError(error: err), orSuccess: orSuccess)
//        } else {
//            return .success(orSuccess)
//        }
    }
    
    static func fromError<ShadowSuccess>(_ error:(any Error)?, orSuccess:ShadowSuccess)->MNResult<ShadowSuccess> {
        if let mnError = error as? MNError {
            return Self.fromMNError(mnError, orSuccess: orSuccess)
        } else if let err = error {
            return Self.fromMNError(MNError(error: err), orSuccess: orSuccess)
        } else {
            return .success(orSuccess)
        }
    }
    
    static func fromMNError<ShadowSuccess>(_ mnError:MNError?, orSuccess:ShadowSuccess)->MNResult<ShadowSuccess> {
        if let mnError = mnError {
            return .failure(mnError)
        } else {
            return .success(orSuccess)
        }
    }
}

// Description for CustomStringConvertibles
public extension Result where Success : CustomStringConvertible, Failure : CustomStringConvertible {
    var description : String {
        switch self {
        case .success(let success):
            return ".success(\(success.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        case .failure(let err):
            return ".failure(\(err.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        }
    }
}

public extension Result where Success : Sequence {
    
    /// Returns a result with a success value of the first item from the sequence, or a failure.
    /// - Returns: Result with either one element from the sequence.
    func asSingluarItemResult(expecting:Int = 1)->Result<Success.Element?, Failure> {
        switch self {
        case .success(let seq):
            let arr = Array(seq)
            if MNUtils.debug.IS_DEBUG && (arr.count != expecting) {
                print("⚠️️ Result.asSingluarItemResult() called on a sequence with \(arr.count) items. expected \(expecting) item!")
            }
            return .success(arr.first)
        case .failure(let err):
            return .failure(err)
        }
    }
}
