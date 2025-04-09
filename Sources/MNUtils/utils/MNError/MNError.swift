//
//  MNError.swift
//  grafo
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label:"MNError")

public struct MNErrorStruct : JSONSerializable, Hashable, Equatable {
    public let error_code : Int?
    public let error_domain : String?
    private(set) public var error_reason: String
    private(set) public var underlying_errors : [MNErrorStruct]?
    private(set) public var error_originating_path : String? = nil
    private(set) public var error_request_id : String? = nil
    private(set) public var error_text: String? = nil
    
    // Readonly
    public var error_http_status : HTTPResponseStatus? {
        get {
            if let code = self.error_code {
                return HTTPResponseStatus(statusCode: code) // reason ph
            }
            return nil
        }
    }
    
    public var hasUnderlyingError : Bool {
        return self.underlying_errors?.count ?? 0 > 0
    }
    
    public init() {
        // Empty init
        error_code = 0
        error_domain = MNDomains.DEFAULT_DOMAIN + ".MNError"
        error_reason = "Unknown error"
        underlying_errors = nil
    }
    
    public init(error_code code: Int? = nil,
        error_domain domain: String? = nil,
        error_reason reason: String? = nil,
        underlying_errors underlying: [MNErrorStruct]? = nil) {
            // Set values
        error_code = code ?? 0
        error_domain = domain ?? MNDomains.DEFAULT_DOMAIN + ".MNError"
        error_reason = reason ?? "Unknown error"
        underlying_errors = underlying
    }
    
    mutating private func appendAsUnderlyingError(mnErrors:[MNError]?, recurseUnderlyingErrors:Bool = true) {
        guard let mnErrors = mnErrors, mnErrors.count > 0 else {
            return
        }
        var structs : [MNErrorStruct] = []
        for mnError in mnErrors {
            structs.append(MNErrorStruct(mnError: mnError, recurseUnderlyingErrors: false))
            
            // Add underlying errors recurively (as a flattened array):
            if recurseUnderlyingErrors {
                if let uerrors = mnError.underlyingErrorsCollated(), uerrors.count > 0 {
                    structs.append(contentsOf:
                        uerrors.map({ mnErr in
                        MNErrorStruct(mnError: mnError, recurseUnderlyingErrors: false)
                    }))
                }
            }
        }
        
        self.appendAsUnderlyingError(structs: structs)
    }
    
    mutating private func appendAsUnderlyingError(structs:[MNErrorStruct]?) {
        guard let structs = structs, structs.count > 0 else {
            return
        }
        
        let array =  (self.underlying_errors ?? [])
        underlying_errors = array.appending(contentsOf: structs).compactMap({ underlyingError in
            if underlyingError.error_code != self.error_code || underlyingError.error_domain != self.error_domain {
                return underlyingError
            } else if underlyingError.self.error_reason != self.error_reason {
                if self.error_reason == self.mnErrorCode()?.httpStatus?.reasonPhrase &&
                    underlyingError.error_reason != underlyingError.mnErrorCode()?.httpStatus?.reasonPhrase {
                    // Change self resons to the non-default reason
                    self.error_reason = underlyingError.error_reason
                } else {
                    return underlyingError
                }
            }
            return nil
        }).uniqueElements()
        
        if underlying_errors?.count == 0 {
            underlying_errors = nil
        }
    }
    
    public init(mnError:MNError, recurseUnderlyingErrors:Bool = true) {
        error_code = mnError.code
        error_domain = mnError.domain
        error_reason = mnError.reason
        self.underlying_errors = nil
        
        // After init:
        if recurseUnderlyingErrors {
            self.appendAsUnderlyingError(mnErrors: mnError.underlyingErrorsCollated(), recurseUnderlyingErrors: false)
        }
    }
    
    public init(error:any Error) {
        self.init(mnError: MNError(error: error))
    }
    
    public mutating func update(originatingPath:String) {
        error_originating_path = originatingPath
    }
    public mutating func update(reqId:String) {
        error_request_id = reqId
    }
    public mutating func update(errorText:String) {
        error_text = errorText
    }
    public mutating func update(underlyingErrorStructs:[MNErrorStruct]) {
        self.appendAsUnderlyingError(structs: underlyingErrorStructs)
    }
    
    public mutating func update(underlyingMNErrors mnErrors:[MNError]) {
        self.appendAsUnderlyingError(mnErrors: mnErrors, recurseUnderlyingErrors: false)
    }
    
    public mutating func update(underlyingErrors errors:[Error]) {
        let mnErrors = errors.map { MNError(error: $0) }
        self.appendAsUnderlyingError(mnErrors: mnErrors, recurseUnderlyingErrors: false)
    }
    
    public func mnErrorCode()->MNErrorCode? {
        guard let code = error_code else {
            return nil
        }
        return MNErrorCode(rawValue: code)
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(error_code)
        hasher.combine(error_domain)
        hasher.combine(error_reason)
        hasher.combine(underlying_errors)
        hasher.combine(error_originating_path)
        hasher.combine(error_request_id)
    }
}

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
    private(set) public var underlyingError:MNError?
    private(set) public var reasons:[String]?
        
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
    
    public var httpStatus : HTTPResponseStatus? {
        return mnErrorCode()?.httpStatus
    }
    
    public var httpStatusCode : Int? {
        guard let uintCode = mnErrorCode()?.httpStatusCode else {
            return nil
        }
        return Int(uintCode)
    }
    
    public var localizedDescription: String {
        get {
            return desc
        }
    }
    
    public var debugDescription: String {
        var str = "<MNError \(self.domain) \(self.code)> [\(self.reason)]"
        if self.hasUnderlyingError, let lines = self.underlyingErrorsCollated()?.descriptionLines {
            str += lines
        }
        if ["PostgresNIO.PSQLError"].contains(str) {
            str += "\(self)"
        }
        return str
        
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
            dlog?.warning("MNError.init(domain:newCode:description:reasons:underlyingError) Exception: Desc: \(self.desc)\n code: \(self.code) domain: \(self.domain) description: \(self.description) lines: \(self.reasons?.descriptionLines ?? "<no reason/s>")")
        }
        #endif
    }
    
    public func underlyingErrorsCollated()->[MNError]? {
        var result : [MNError] = []
        var err = self.underlyingError
        while err != nil {
            if let err = err {
                result.append(err)
            }
            err = err?.underlyingError
        }
        
        if result.count == 0 {
            return nil
        }
        return result
    }
    
    public func setUnderlyingError(err:MNError) {
        if self != err && self.underlyingError != err {
            self.underlyingError = err
        }
    }
    
    
    /// recursively search for any newsted underlying error with this code
    /// - Parameter code: error code to search
    public func hasUnderlyingError(code:MNErrorCode)->Bool {
        return self.hasUnderlyingError(code:code.code)
    }
    public func hasUnderlyingError(code:MNErrorInt)->Bool {
        var result = false
        var err = self.underlyingError
        while err != nil {
            if let err = err {
                if err.code == code {
                    result = true
                    break
                }
            }
            err = err?.underlyingError
        }
        
        return result
    }
    
    // @discardableResult
    /// Will add the error as most nested underlying error in the nested .underlyingError list
    ///  NOTE: We ignore / do not set an error equal to any one of its parents.
    /// - Parameter error: error to set as the most-nested error
    public func setMostNestedUnderlyingError(_ error:MNError) {
        var err : MNError? = self
        while err?.hasUnderlyingError == true {
            if err == error {
                // We ignore / do not set an error equal to any one of its parents.
                return
            }
            err = err?.underlyingError
        }
        err?.setUnderlyingError(err: error)
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
    public convenience init(fromError curError:MNError, withUnderlyingError newUnderlyingErr : MNError) {
        self.init(domain: curError.domain, code: curError.code, description: curError.desc,
                  reasons: curError.reasons,
                underlyingError: newUnderlyingErr)
    }
    
    /// Init using a given NSError
    ///
    /// - Parameter nserror: NSError to convert to MNError
    public init (nserror:NSError, reason:String? = nil) {
        
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
    public convenience init(fromOther other:MNErrorCodable, reason:String? = nil, underlyingError:(any Error)? = nil) {
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
    public convenience init(fromOther other:MNErrorCodable, /*we needed to use this name for disambiguation details->*/reasonsArray:[String]?, underlyingError:(any Error)? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        
        self.init(domain:other.domain, code:other.code, description:other.desc, reasons: reasonsArray, underlyingError:saunderlying)
    }
    
    
    public convenience init(code:MNErrorCode, reasons newReasons:[String]?, underlyingError:(any Error)? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        let adomain = code.domain
        self.init(domain:adomain,
                  errcode:code,
                  description:code.desc,
                  reasons: newReasons,
                  underlyingError: saunderlying)
    }
    

    public convenience init(code:MNErrorCode, reason : String?, underlyingError:(any Error)? = nil){
        self.init(code: code, reasons: reason != nil ? [reason!] : nil, underlyingError:underlyingError)
    }
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - reasons: (optional) array of details describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    public convenience init(code:MNErrorCodable, reasons newReasons:[String]?, underlyingError:(any Error)? = nil) {
        let saunderlying : MNError? = (underlyingError as? MNError) ?? MNError(error:underlyingError)
        self.init(domain:code.domain, code:code.code, description:code.desc, reasons: newReasons, underlyingError: saunderlying)
    }
    
    
    /// Init an SAError using any Error
    ///
    /// - Parameter error: error to be converted to an SAError
    public convenience init(error: any Error) {
        #if DEBUG
        if String(describing:type(of: error)) == "SAError" {
            dlog?.warning("Error converted to error [1]")
            preconditionFailure("Error converted to error [1]")
        }
        #endif
        
        self.init(nserror: error as NSError)
    }
    
    /// Conveniene optional init an SAError using any Error?
    /// May return nil if provided error is nil
    ///
    /// - Parameter error: error to be converted to an SAError
    public convenience init?(error:(any Error)?) {
        #if DEBUG
            if String(describing:type(of: error)) == "SAError" {
                dlog?.warning("Error converted to error [2]")
                preconditionFailure("Error converted to error [2]")
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
    
    private func trackError(error:any Error) {
        var mnError = error as? MNError
        if mnError == nil {
            mnError = MNError(error: error)
        }
        
        self.trackError(mnError: mnError!)
    }
}

public extension MNError /*mnErrors*/ {
    
    convenience init(fromError input:(any Error)?, defaultErrorCode:MNErrorCode, reason:String?) {
        self.init(fromError:input, defaultErrorCode:defaultErrorCode, reasons:reason != nil ? [reason!] : [])
    }
    
    convenience init(fromError input:(any Error)?, defaultErrorCode:MNErrorCode, reasons:[String]?) {
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
                self.init(code:MNErrorCode.web_internet_connection_error, reasons:reasons, underlyingError:underError)
            case (3, "Alamofire.AFError"):
                self.init(code:MNErrorCode.web_unexpected_response, reasons:reasons, underlyingError:underError)
            default:
                self.init(code:defaultErrorCode, reasons: reasons, underlyingError: underError)
            }
        } else {
            self.init(code:defaultErrorCode, reasons: reasons, underlyingError: underError)
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

extension MNResult3 where Failure : MNError {
    
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
