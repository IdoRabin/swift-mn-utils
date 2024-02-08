//
//  MNBootState.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

// fileprivate let dlog : Logger? = Logger(label: "MNBootState")?.setting(verbose: true)

public enum MNBootState : Int, Equatable, Comparable, CaseIterable {
    
    case unbooted = 0
    case booting
    case running
    case saving
    case loading
    case shuttingDown
    case shutDown = 99
    
    // MARK: Comparable
    public static func < (lhs: MNBootState, rhs: MNBootState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension MNBootState : CustomStringConvertible {
    public var description: String {
        switch self {
        case .unbooted: return "unbooted"
        case .booting: return "booting"
        case .running: return "running"
        case .saving: return "saving"
        case .loading: return "loading"
        case .shuttingDown: return "shuttingDown"
        case .shutDown: return "shutDown"
        }
    }
}
