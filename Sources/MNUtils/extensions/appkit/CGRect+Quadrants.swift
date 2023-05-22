//
//  CGRect+Quadrants.swift
//  grafo
//
//  Created by Ido on 22/01/2023.
//

import Cocoa

enum CGQuadrant : CustomStringConvertible {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    
    var flippedY : CGQuadrant {
        switch self {
        case .topLeft:      return .bottomRight
        case .topRight:     return .bottomLeft
        case .bottomLeft:   return .topRight
        case .bottomRight:  return .topLeft
        }
    }
    
    var flippedX : CGQuadrant {
        switch self {
        case .topLeft:      return .topRight
        case .topRight:     return .topLeft
        case .bottomLeft:   return .bottomRight
        case .bottomRight:  return .bottomLeft
        }
    }
    
    var description: String {
        switch self {
        case .topLeft: return "topLeft"
        case .topRight: return "topRight"
        case .bottomLeft: return "bottomLeft"
        case .bottomRight: return "bottomRight" 
        }
    }
}

extension CGRect {
    var quadrent : CGQuadrant {
        if self.size.width > 0 {
            if self.size.height > 0 {
                return .bottomRight
            } else {
                return .topRight
            }
        } else {
            if self.size.height > 0 {
                return .bottomLeft
            } else {
                return .topLeft
            }
        }
    }
}
