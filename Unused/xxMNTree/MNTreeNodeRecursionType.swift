//
//  MNTreeNodeRecursionType.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

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
