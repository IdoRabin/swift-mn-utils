//
//  File.swift
//  
//
//  Created by Ido on 18/03/2023.
//

import Foundation

// Target output
public struct MNLogOutput: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let console = MNLogOutput(rawValue: 1 << 0)
    static let regularFile = MNLogOutput(rawValue: 1 << 1)
    static let errorsFile = MNLogOutput(rawValue: 1 << 2)
    
    static let all: MNLogOutput = [.console, .regularFile, .errorsFile]
    static let allArray =  Array<MNLogOutput>([.console, .regularFile, .errorsFile])
}

// Filtered "granularity" : LOD
public enum MNLogGranularity : String, Comparable, CaseIterable {
    
    case verbose
    case `default`
    case warningsOnly
    case disabled
    
        /// All elements, sorted by order of 'verbosity'
    static var all : [MNLogGranularity] = [.disabled, .warningsOnly, .default, .verbose]
    
    // MARK: Comparable
    public static func < (lhs: MNLogGranularity, rhs: MNLogGranularity) -> Bool {
        let lidx = Self.all.firstIndex(of: lhs) ?? -1
        let ridx = Self.all.firstIndex(of: rhs) ?? -1
        return lidx < ridx
    }
}

// Log level: 'describes' the event triggering the log event
public enum MNLogLevel : String {
    case info
    case success
    case fail
    case note
    case warning
    case todo
    case raisePrecondition
    case assertFailure
}

// TODO: Transition to a filter set
//public struct MNLogFilter {
//    let granularity : MNLogGranularity
//    let level : MNLogLevel
//    let including : [String]
//    let excluding : [String]
//}
