//
//  Vapor+Error.swift
//  
//
//  Created by Ido on 16/11/2022.
//

#if VAPOR

import Foundation
import Vapor

public extension Abort {
    init(mnErrorCode mneCode:MNErrorCode, reason areason:String? = nil) {
        if mneCode.isHTTPStatus {
            self.init(mneCode.httpStatusCode!)
        } else {
            self.init(.custom(code: UInt(mneCode.code), reasonPhrase: areason ?? mneCode.reason))
        }
    }
}

#endif
