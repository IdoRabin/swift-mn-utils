//
//  MNError.swift
//  grafo
//
//  Created by Ido on 10/07/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : MNLogger? = MNLog.forClass("MNError")

/// App class of error, is derived from Error, but can be initialized by AppError codes and also in concurrance with NSErrors and other Errors and underlying errors / filtered before determining eventual error code
/// The main aim in this class is to wrap each error raised in the app from any source into a more organized state
open class MNError : Error, MNErrorable, JSONSerializable, CustomDebugStringConvertible {
    
    // Codable
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case domain = "domain"
        case code = "code"
        case underlyingError = "underlyingError"
        case desc = "desc" // we use desc because "description" is used by CustomStringConvertible protocol
        case reasons = "reasons"
    }
    
    // Base members
    public let domain : String
    public let code:MNErrorInt
    public let desc : String
    private (set) public var underlyingError:MNError?
    private (set) public var reasons:[String]?

    public func mnErrorCode() -> MNErrorCode? {
        guard let result = MNErrorCode(rawValue:code) else {
            return nil
        }
        return result
    }
    
    public func mnErrorCode() throws -> MNErrorCode  {
        guard let result = MNErrorCode(rawValue:code) else {
            throw MNError(MNErrorCode.misc_failed_decoding, reason:"MNError failed converting code [\(code)] to MNErrorCode!")
        }
        return result
    }
    
    public var localizedDescription: String {
        get {
            return desc
        }
    }
    
    public var debugDescription: String {
        return "<MNError \(self.domain) \(self.code)> [\(self.reason)]"
    }
    
    public var hasUnderlyingError : Bool {
        return underlyingError != nil
    }
    
    public var reasonsLines: String? {
        guard let reasons = reasons else {
            return nil
        }
        
        if reasons.count > 1 {
            return reasons.descriptionLines
        }
        return reasons.first
    }
    
    public var reason: String {
        get {
            return reasonsLines ?? self.desc
        }
        set {
            if newValue.count > 0 {
                if let reas = reasons {
                    if !reas.contains(newValue) {
                        reasons?.append(newValue)
                    }
                } else {
                    reasons = [newValue]
                }
            }
        }
    }
    
    private func validatSelf() {
        #if DEBUG
        if self.desc.contains("couldn't") {
            dlog?.warning("MNError.init(domain:newCode:description:reasons:underlyingError) Exception: Desc: \(desc)\n code: \(self.code) domain: \(self.domain) description: \(self.description) lines: \(self.reasons?.descriptionLines ?? "<no reason/s>")")
        }
        #endif
    }
    
    public func setUnderlyingError(err:MNError) {
        if self != err && self.underlyingError != err {
            self.underlyingError = err
        }
    }
    /// Init in base level (try not to use this init)
    ///
    /// - Parameters:
    ///   - newDomain: domain of error.
    ///   - newCode: code of error
    ///   - newDescription: description of error (should b localized)
    ///   - newReasons: array of strings that detail the cause and exact situation where the error was raisedd (developer eyes only)
    ///   - newUnderlyingError: underlying error that was reaised befoer or was the cause to the main error
    init(domain newDomain:String, code newCode:MNErrorInt, description newDescription:String, reasons newReasons:[String]? = nil, underlyingError newUnderlyingError:MNError?) {
        
        // Init members
        domain = newDomain
        code = newCode
        desc = newDescription
        underlyingError = newUnderlyingError
        reasons = newReasons
        
        self.validatSelf()
        
        // Tracks any error created
        self.trackError(error: self)
    }
    
    public convenience init(domain newDomain:String? = nil, errcode newCode:MNErrorCode, description newDescription:String, reasons newReasons:[String]? = nil, underlyingError newUnderlyingError:MNError?) {
        let adomain = newDomain ?? newCode.domain
        self.init(domain: adomain, code: newCode.rawValue, description: newDescription, reasons: newReasons, underlyingError: newUnderlyingError)
    }
    
    
    /// Will duplicate existing error but will set the provided underlying error
    /// - Parameters:
    ///   - fromError: curArror the error to duplicate with an additional underlying error
    ///   - withUnderlyingError: underlying erro to set in the new error
    convenience init(fromError curError:MNError, withUnderlyingError newUnderlyingErr : MNError) {
        self.init(domain: curError.domain, code: curError.code, description: curError.desc,
                  reasons: curError.reasons,
                underlyingError: newUnderlyingErr)
    }
    
    /// Init using a given NSError
    ///
    /// - Parameter nserror: NSError to convert to MNError
    init (nserror:NSError, reason:String? = nil) {
        
        // Init memebrs from the NSError:
        domain = nserror.domain
        code = nserror.code
        desc = nserror.localizedDescription
        var newReasons : [String] = []
        
        // Add detail param to details array
        if let reason = reason {
            newReasons.append(reason)
        }
        
        // Add other userInfo keys as details
        if nserror.userInfo.count > 0 {
            for (key,value) in nserror.userInfo {
                let aKey = key.replacingOccurrences(of: "NSValidationErrorKey", with: "❗NSValidationErrorKey")
                newReasons.append("\(aKey) : \(value)")
            }
        }
        reasons = (newReasons.count > 0) ? newReasons : nil
        
        // Copy underlying error (but convert to AppError as well)
        if let underlyingError = nserror.userInfo[NSUnderlyingErrorKey] as? NSError {
            self.underlyingError = MNError(nserror: underlyingError)
        } else {
            self.underlyingError = nil
        }
        
        self.validatSelf()
        
        // Tracks any error created
        self.trackError(error: self)
    }
    
    
    /// Init an MNError using any AppErrorCodable
    ///
    /// - Parameters:
    ///   - fromOther: any AppErrorCodable to deraive the properties of the new error (see AppErrors)
    ///   - reason: (optional) reason describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(fromOther other:MNErrorCodable, reason:String? = nil, underlyingError:Error? = nil) {
        var newReasons : [String]? = nil
        if let reason = reason {
            newReasons = [reason]
        }
        self.init(fromOther:other, reasonsArray:newReasons, underlyingError:underlyingError)
    }
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - fromOther:any AppErrorCodable to deraive the properties of the new error (see AppErrors)
    ///   - reasons: (optional) reasons array describing the exact situations raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(fromOther other:MNErrorCodable, /*we needed to use this name for disambiguation details->*/reasonsArray:[String]?, underlyingError:Error? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        
        self.init(domain:other.domain, code:other.code, description:other.desc, reasons: reasonsArray, underlyingError:saunderlying)
    }
    
    
    convenience init(code:MNErrorCode, reasons newReasons:[String]?, underlyingError:Error? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        let adomain = code.domain
        self.init(domain:adomain,
                  errcode:code,
                  description:code.desc,
                  reasons: newReasons,
                  underlyingError: saunderlying)
    }
    

    public convenience init(code:MNErrorCode, reason : String?, underlyingError:Error? = nil){
        self.init(code: code, reasons: reason != nil ? [reason!] : nil, underlyingError:underlyingError)
    }
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - reasons: (optional) array of details describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(_ code:MNErrorCodable, reasons newReasons:[String]?, underlyingError:Error? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        self.init(domain:code.domain, code:code.code, description:code.desc, reasons: newReasons, underlyingError: saunderlying)
    }
    
    
    /// Init an SAError using any Error
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init(error:Error) {
        #if DEBUG
        if String(describing:type(of: error)) == "SAError" {
            dlog?.raiseAssertFailure("Error converted to error")
        }
        #endif
        
        self.init(nserror: error as NSError)
    }
    
    /// Conveniene optional init an SAError using any Error?
    /// May return nil if provided error is nil
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init?(error:Error?) {
        #if DEBUG
            if String(describing:type(of: error)) == "SAError" {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        if let error = error {
            self.init(nserror: error as NSError)
        }
        return nil
    }
    
    // Track error:
    
    /// Track an error using the AppTracking mechanism (analytics)
    ///
    /// - Parameter error: an SAError to be sent to the analytics system
    private func trackError(mnError:MNError) {
        // let errorName = "error:" + error.domain + " code:" + String(error.code)
        
        // Create params for the analytics system:
        var params : [String:Any] = [:]
        params["description"] = mnError.desc
        if let foundReasons = mnError.reasons {
            params["reasons"] = foundReasons.joined(separator: "|")
        }
        
        // Add params for the underlying error
        if let underlyingError = mnError.underlyingError {
            let desc = "error:" + underlyingError.domain + " code:" + String(underlyingError.code)
            params["underlying_error"] = desc
            params["underlying_error_desc"] = underlyingError.desc
            if let underReasons = underlyingError.reasons {
                params["underlying_error_reasons"] = underReasons.joined(separator: "|")
            }
        }
        
        // Param values can be up to 100 characters long. The "firebase_", "google_" and "ga_" prefixes are reserved and should not be used
        #if os(OSX)
        // AppTracking.shared.trackEvent(category: TrackingCategory.Errors, name: errorName, parameters:(params.count > 0 ? params : nil))
        #elseif os(iOS)
        // Does nothing
        #endif
    }
    
    private func trackError(error:Error) {
        var mnError = error as? MNError
        if mnError == nil {
            mnError = MNError(error: error)
        }
        
        self.trackError(mnError: mnError!)
    }
}

public extension MNError /*mnErrors*/ {
    
    convenience init(fromError input:Error?, defaultErrorCode:MNErrorCode, reason:String?) {
        self.init(fromError:input, defaultErrorCode:defaultErrorCode, reasons:reason != nil ? [reason!] : [])
    }
    
    convenience init(fromError input:Error?, defaultErrorCode:MNErrorCode, reasons:[String]?) {
        if let mnError = input as? MNError {
            self.init(domain:mnError.domain, code:mnError.code, description:mnError.desc, reasons: reasons, underlyingError: nil)
        } else if let nsError = input as? NSError {
            self.init(fromNSError: nsError, defaultErrorCode: defaultErrorCode, reasons: reasons)
        } else {
            self.init(code:defaultErrorCode, reasons:reasons)
        }
    }
    
    convenience init(fromNSError underError:NSError?, defaultErrorCode:MNErrorCode, reason:String? = nil) {
        let reasons : [String]? = reason != nil ? [reason!] : nil
        self.init(fromNSError: underError as NSError?, defaultErrorCode: defaultErrorCode, reasons: reasons)
    }
    
    convenience init(fromNSError underError:NSError?, defaultErrorCode:MNErrorCode, reasons:[String]?) {
        if let underError = underError {
            switch (underError.code, underError.domain) {
            case (-1009, NSURLErrorDomain), (-1003, NSURLErrorDomain), (-1004, NSURLErrorDomain), (-1001, NSURLErrorDomain):
                self.init(MNErrorCode.web_internet_connection_error, reasons:reasons, underlyingError:underError)
            case (3, "Alamofire.AFError"):
                self.init(MNErrorCode.web_unexpected_response, reasons:reasons, underlyingError:underError)
            default:
                self.init(defaultErrorCode, reasons: reasons, underlyingError: underError)
            }
        } else {
            self.init(defaultErrorCode, reasons: reasons, underlyingError: underError)
        }
    }
}

extension MNError : Equatable {
    public static func == (lhs: MNError, rhs: MNError) -> Bool {
        var result = lhs.domain == rhs.domain && lhs.code == rhs.code
        if result {
            if lhs.hasUnderlyingError != rhs.hasUnderlyingError {
                result = false
            } else if let lhsu = lhs.underlyingError, let rhsu = rhs.underlyingError {
                result = lhsu == rhsu
            }
        }
        return result
    }
}

extension MNError : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.code)
        hasher.combine(self.reasons)
        hasher.combine(self.reason)
    }
}

extension Result3 where Failure : MNError {
    
    var mnError : MNError? {
        switch self {
        case .successNoChange: return nil
        case .successChanged: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}

extension Result where Failure : MNError {
    
    var mnError : MNError? {
        switch self {
        case .success: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}
