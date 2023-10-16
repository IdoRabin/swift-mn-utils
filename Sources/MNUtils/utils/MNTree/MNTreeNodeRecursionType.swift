//
//  MNTreeNodeRecursionType.swift
//  
//
//  Created by Ido on 06/09/2023.
//

import Foundation

public enum MNTreeNodeRecursionType : Int, CustomStringConvertible, CaseIterable {
    case depthFirst = 1
    case breadthFirst = 2
    
    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .depthFirst: return "depthFirst"
        case .breadthFirst: return "breadthFirst"
        }
    }
}
