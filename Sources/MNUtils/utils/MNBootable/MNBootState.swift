//
//  MNBootState.swift
//  
//
//  Created by Ido on 10/06/2023.
//

import Foundation
//import DSLogger

// fileprivate let dlog : DSLogger? = DLog.forClass("MNBootState")?.setting(verbose: true)

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
