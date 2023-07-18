//
//  MNErrorCode.swift
//
//
//  Created by Ido on 08/11/2023.
//

import Foundation

public extension MNError {
    convenience init(_ code: MNErrorCode, reason: String) {
        self.init(code: code, reasons: [reason])
    }

    convenience init(_ code: MNErrorCode, reasons: [String]) {
        self.init(code: code, reasons: reasons)
    }
}

public typealias MNErrorInt = Int

public enum MNErrorCode: MNErrorInt, MNErrorCodable, CaseIterable {
    //  - If there is any codes / domains BEFORE http statuses -
    // MAXRANGE: 99
    
    // iana HTTPResponseStatus (in swift-nio)
    // 1xx
    case http_stt_continue = 100
    case http_stt_switchingProtocols
    case http_stt_processing
    // TODO: add '103: Early Hints' when swift-nio upgrades

    // iana HTTPResponseStatus (in swift-nio)
    // 2xx
    case http_stt_ok = 200
    case http_stt_created
    case http_stt_accepted
    case http_stt_nonAuthoritativeInformation
    case http_stt_noContent_204
    case http_stt_resetContent
    case http_stt_partialContent
    case http_stt_multiStatus
    case http_stt_alreadyReported
    case http_stt_imUsed

    // iana HTTPResponseStatus (in swift-nio)
    // 3xx
    case http_stt_multipleChoices = 300
    case http_stt_movedPermanently
    case http_stt_found
    case http_stt_seeOther
    case http_stt_notModified
    case http_stt_useProxy
    case http_stt_temporaryRedirect
    case http_stt_permanentRedirect

    // iana HTTPResponseStatus (in swift-nio)
    // 4xx
    case http_stt_badRequest = 400
    case http_stt_unauthorized // 401
    case http_stt_paymentRequired  // 402
    case http_stt_forbidden         // 403
    case http_stt_notFound          // 404
    case http_stt_methodNotAllowed    // 405
    case http_stt_notAcceptable        // 406
    case http_stt_proxyAuthenticationRequired // 407
    case http_stt_requestTimeout            // 408
    case http_stt_conflict              // 409
    case http_stt_gone                  // 410
    case http_stt_lengthRequired        // 411
    case http_stt_preconditionFailed    // 412
    case http_stt_payloadTooLarge       // 413
    case http_stt_uriTooLong            // 414
    case http_stt_unsupportedMediaType  // 415
    case http_stt_rangeNotSatisfiable   // 416
    case http_stt_expectationFailed
    case http_stt_imATeapot
    case http_stt_misdirectedRequest
    case http_stt_unprocessableEntity
    case http_stt_locked
    case http_stt_failedDependency
    case http_stt_upgradeRequired
    case http_stt_preconditionRequired
    case http_stt_tooManyRequests
    case http_stt_requestHeaderFieldsTooLarge
    case http_stt_unavailableForLegalReasons

    // Other names for HTTP status codes Vapor introduced:
    /// Input was syntactically correct, but not semantically (usually failed validations).
    static let http_stt_invalid_input = Self.http_stt_notAcceptable // 406 not acceptable
    /// requested data not found, while the request URI exists and is valid, and input data is valid and yielded an empty collection of object/s
    static let http_stt_data_not_found_204 = Self.http_stt_noContent_204 // 204 No content

    // iana HTTPResponseStatus (in swift-nio)
    // 5xx
    case http_stt_internalServerError = 500
    case http_stt_notImplemented
    case http_stt_badGateway
    case http_stt_serviceUnavailable
    case http_stt_gatewayTimeout
    case http_stt_httpVersionNotSupported
    case http_stt_variantAlsoNegotiates
    case http_stt_insufficientStorage
    case http_stt_loopDetected
    case http_stt_notExtended
    case http_stt_networkAuthenticationRequired
    static var allHTTPStatus: [MNErrorCode] {
        var result: [MNErrorCode] = []
        for i in 100 ... 599 {
            if let code = MNErrorCode(rawValue: i) {
                result.append(code)
            }
        }
        return result
    } // MAXRANGE: 599

    static var anyHTTPStatus: [MNErrorCode] {
        return allHTTPStatus
    }

    // Cancel
    case canceled_by_user = 8001
    case canceled_by_server = 8002
    case canceled_by_client = 8003
    static let allCancel: [MNErrorCode] = [.canceled_by_user, .canceled_by_server, .canceled_by_client]
    static var anyCancel: [MNErrorCode] = allCancel
    // MAXRANGE: 8999

    // Misc
    case misc_unknown = 9000
    case misc_failed_loading = 9001
    case misc_failed_saving = 9002
    case misc_operation_canceled = 9003
    case misc_failed_creating = 9010
    case misc_failed_removing = 9011
    case misc_failed_inserting = 9012
    case misc_failed_updating = 9013
    case misc_failed_reading = 9014
    case misc_no_permission_needed = 9019 //
    case misc_no_permission_for_operation = 9020 //
    case misc_readonly_permission_for_operation = 9021 //
    case misc_failed_crypto = 9022
    case misc_failed_parsing = 9030
    case misc_failed_encoding = 9031
    case misc_failed_decoding = 9032
    case misc_failed_validation = 9033
    case misc_already_exists = 9034
    case misc_security = 9050
    case misc_concurrency = 9060
    // MAXRANGE: 9999
    
    static let allMisc: [MNErrorCode] = [
        .misc_unknown, .misc_failed_loading, .misc_failed_saving, .misc_operation_canceled, .misc_failed_creating,
        .misc_failed_removing, .misc_failed_inserting, .misc_failed_updating, .misc_failed_reading,
        .misc_no_permission_needed, .misc_no_permission_for_operation, .misc_readonly_permission_for_operation, .misc_failed_crypto,
        .misc_failed_parsing, .misc_failed_encoding, .misc_failed_decoding,
        .misc_failed_validation, .misc_already_exists, .misc_security, .misc_concurrency
    ]

    // Web
    case web_unknown = 1000
    case web_internet_connection_error = 1003
    case web_unexpected_response = 1100
    static let allWeb: [MNErrorCode] = [
        .web_unknown, .web_internet_connection_error, .web_unexpected_response,
    ]
    // MAXRANGE: 1200

    // Command
    case cmd_not_allowed_now = 1500 // no permission?
    case cmd_failed_execute = 1501
    case cmd_failed_undo = 1502
    static let allCommand: [MNErrorCode] = [
        .cmd_not_allowed_now, .cmd_failed_execute, .cmd_failed_undo,
    ]
    // MAXRANGE: 1600

    // Doc
    case doc_unknown = 2000
    case doc_create_new_failed = 2010
    case doc_create_from_template_failed = 2011
    case doc_open_existing_failed = 2012
    case doc_save_failed = 2013
    case doc_load_failed = 2014
    case doc_close_failed = 2015
    case doc_change_failed = 2016
    static let allDocChange: [MNErrorCode] = [
        .doc_unknown, .doc_create_new_failed, .doc_create_from_template_failed,
        .doc_open_existing_failed, .doc_save_failed, .doc_load_failed, .doc_close_failed, .doc_change_failed,
    ]
    // MAXRANGE: 2029

    // Layer
    case doc_layer_insert_failed = 2030
    case doc_layer_insert_undo_failed = 2031
    case doc_layer_move_failed = 2032
    case doc_layer_move_undo_failed = 2033
    case doc_layer_delete_failed = 2040
    case doc_layer_delete_undo_failed = 2041
    case doc_layer_already_exists = 2050
    case doc_layer_lock_unlock_failed = 2051
    case doc_layer_select_deselect_failed = 2052
    case doc_layer_search_failed = 2060
    case doc_layer_change_failed = 2070
    static let allDocLayer: [MNErrorCode] = [
        .doc_layer_insert_failed, .doc_layer_insert_undo_failed, .doc_layer_move_failed,
        .doc_layer_move_undo_failed, .doc_layer_delete_failed,
        .doc_layer_delete_undo_failed, .doc_layer_already_exists, .doc_layer_lock_unlock_failed,
        .doc_layer_select_deselect_failed, .doc_layer_search_failed, .doc_layer_change_failed,
    ]
    // MAXRANGE: 2090

    // User
    case user_login_failed = 2501
    case user_login_failed_no_permission = 2502
    case user_login_failed_bad_credentials = 2503
    case user_login_failed_permissions_revoked = 2504
    case user_login_failed_user_name = 2505
    case user_login_failed_password = 2506
    case user_login_failed_name_and_password = 2507
    case user_login_failed_user_not_found = 2508
    static let allUserLogin: [MNErrorCode] = [
        .user_login_failed, .user_login_failed_no_permission, .user_login_failed_bad_credentials,
        .user_login_failed_permissions_revoked,
        .user_login_failed_user_name,
        .user_login_failed_password,
        .user_login_failed_name_and_password, .user_login_failed_user_not_found,
    ]

    case user_logout_failed = 2530
    static let allUserLogout: [MNErrorCode] = [
        .user_logout_failed,
    ]

    case user_invalid_username = 2540 // sanitization
    case user_invalid_user_input = 2541 // sanitization
    static let allUsername: [MNErrorCode] = [
        .user_invalid_username, user_invalid_user_input,
    ]

    // db
    case db_unknown = 3000
    case db_failed_init = 3010
    case db_failed_migration = 3011
    case db_skipped_migration = 3012
    case db_failed_load = 3013
    case db_failed_query = 3014
    
    case db_failed_fetch_request = 3020
    // case db_failed_fetch_by_ids = 3021
    // case db_failed_creating_fetch_request = 3022
    // case db_failed_update_request = 3030
    // case db_failed_save = 3040
    // case db_failed_autosave = 3041
    // case db_failed_delete = 3050
    case db_empty_result = 3070
    
    static let allDB: [MNErrorCode] = [
        .db_unknown, .db_failed_init, .db_failed_migration, .db_skipped_migration,
        .db_failed_load, .db_failed_query, .db_failed_fetch_request,
//        .db_failed_fetch_by_ids,
//        .db_failed_creating_fetch_request, .db_failed_update_request, .db_failed_save,
//        .db_failed_autosave, .db_failed_delete,
        .db_empty_result,
   ]

    // UI
    case ui_unknown = 5000

    // == END OF CASES == // marker for autogeneraing script!
    public var domain: String {
        var result : String = "\(Self.self)"
        result += "."
        result += MNErrorDomain.domain(for: self).name
        return result
    }

    public var reason: String {
        return desc
    }

    public var desc: String {
        switch rawValue {
        case 100 ..< 600: // HttpStatus
            return httpStatusCode?.reasonPhrase ?? "TODO.MNErrorCode.httpStatus.desc|\(self.code)"
        default:
            return "TODO.MNErrorCode.desc|\(self.code)"
        }
    }

    public var code: MNErrorInt {
        return rawValue
    }

    public var httpStatusCode : HTTPResponseStatus? {
        // IANA HTTPResponseStatus
        var result : HTTPResponseStatus? = nil
        switch rawValue {
        case 100 ..< 600: // HttpStatus
            return HTTPResponseStatus(statusCode: rawValue)
        default:
            if self.code >= UInt.min && self.code <= UInt.max {
                result = HTTPResponseStatus.custom(code: UInt(self.code), reasonPhrase: self.reason)
            }
        }
        return result
    }
    
    public var isHTTPStatus: Bool {
        return code >= 100 && code < 600
    }
}

public extension Sequence where Element == MNErrorCode {
    var codes: [MNErrorInt] {
        return map { errCode in
            errCode.code
        }
    }

    var intCodes: [Int] {
        return map { errCode in
            Int(errCode.code)
        }
    }
}
