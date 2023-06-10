//
//  MNBootState.swift
//  
//
//  Created by Ido on 10/06/2023.
//

import Foundation
//import DSLogger

// fileprivate let dlog : DSLogger? = DLog.forClass("MNBootState")?.setting(verbose: true)

public enum MNBootState : Int, Equatable {
    case unbooted = 0
    case booting
    case running
    case saving
    case loading
    case shuttingDown
    case shutDown = 99
}
