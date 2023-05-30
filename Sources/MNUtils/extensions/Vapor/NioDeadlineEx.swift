//
//  NIODeadlineEx.swift
//  
//
//  Created by Ido on 26/05/2023.
//

import Foundation

// TODO: check how to compile the MNUtils package for server w/ VAPOR macro when depending target has it.
#if NIO || VAPOR || FLUENT || POSTGRES
import NIOCore

extension NIODeadline /* delayFromNow : TimeInterval */ {
    public static func delayFromNow(_ delay : TimeInterval)->NIODeadline {
        return NIODeadline.now() + .milliseconds(Int64(delay*1000))
    }
    public static func test()->String {
        dlog?.info("Hello test")
    }
}

#endif
