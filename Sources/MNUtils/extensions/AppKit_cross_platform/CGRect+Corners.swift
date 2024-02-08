//
//  CGRect+Corners.swift
//  Bricks
//
// Created by Ido Rabin for Bricks on 17/1/2024.
// Copyright © 2024 Bricks. All rights reserved.
//

import Cocoa

enum LayoutCorner {
    case leadingTop
    case horizCenterTop
    case trailingTop
    case vertCenterLeading
    case leadingBottom
    case horizCenterBottom
    case trailingBottom
    case vertCenterTrailing
    case allCenter
    
    
    /// Returns a point location or a corner on a rectangle related to its frame (takes origin into consideration)
    /// - Parameters:
    ///   - rect: rectanlge to find the corner on
    ///   - isRTL: is the layout direction right_to_left or left-to-right?
    /// - Returns: coordinate of the required corner in relation to the rectangle's frame
    func pointOnRect(rect:CGRect, isRTL : Bool = MNUtils.constants.IS_RTL_LAYOUT)->CGPoint {
        return pointInRectBounds(rect: rect, isRTL: isRTL).offset(xAdd: rect.origin.x, yAdd: rect.origin.y)
    }
    
    /// Returns a point location of a corner inside a rectangle related to its bounds (considers origin as  0,0)
    /// - Parameters:
    ///   - rect: rectanlge to find the corner in
    ///   - isRTL: is the layout direction right_to_left or left-to-right?
    /// - Returns: coordinate of the required corner in relation to the rectangle's bounds
    func pointInRectBounds(rect:CGRect, isRTL : Bool = MNUtils.constants.IS_RTL_LAYOUT)->CGPoint {
        var result : CGPoint = CGPoint.zero
        
        switch self {
        case .leadingTop:
            result = rect.origin
            
        case .horizCenterTop:
            result = rect.center.changed(y: 0)
            
        case .trailingTop:
            result = rect.origin.changed(x: rect.width)
            
        case .vertCenterLeading:
            result = rect.center.changed(x: 0)
            
        case .leadingBottom:
            result = rect.origin.changed(y: rect.height)
            
        case .horizCenterBottom:
            result = rect.center.changed(y: rect.height)
            
        case .trailingBottom:
            result = CGPoint(x: rect.width, y: rect.height)
            
        case .vertCenterTrailing:
            result = rect.center.changed(x: rect.width)
            
        case .allCenter:
            result = rect.center
        }
        
        // Flip x if needed:
        if isRTL {
            result.x = rect.width - result.x
        }
        
        return result
    }
    
    func autoResizingMask()->NSView.AutoresizingMask {
        var mask : NSView.AutoresizingMask = []
        
        // Horiz
        switch self {
        case .leadingTop, .leadingBottom, .vertCenterLeading:
            mask.update(with: .maxXMargin)
        case .trailingBottom, .trailingTop, .vertCenterTrailing:
            mask.update(with: .minXMargin)
        case .horizCenterBottom, .horizCenterTop:
            mask.update(with: .minXMargin)
            mask.update(with: .maxXMargin)
        default:
            break
        }
        
        // vertical
        switch self {
        case .trailingTop, .leadingTop, .horizCenterTop:
            mask.update(with: .minYMargin)
        case .trailingBottom, .leadingBottom, .horizCenterBottom:
            mask.update(with: .maxYMargin)
        case .vertCenterLeading, .vertCenterTrailing:
            mask.update(with: .minYMargin)
            mask.update(with: .maxYMargin)
        default:
            break
        }
        
        return mask
    }
}

extension CGRect /* LayoutCorner */ {
    
    func pointInBounds(for corner:LayoutCorner, isRTL : Bool = MNUtils.constants.IS_RTL_LAYOUT)->CGPoint {
        return corner.pointInRectBounds(rect: self, isRTL: isRTL)
    }
    
    func pointOnRect(for corner:LayoutCorner, isRTL : Bool = MNUtils.constants.IS_RTL_LAYOUT)->CGPoint {
        return corner.pointOnRect(rect: self, isRTL: isRTL)
    }
}

extension CGRect /* Corners + Quadrants */ {
    
    func extremeCornerForQuadrant(_ quad : CGQuadrant)->CGPoint {
        switch quad {
        case .topLeft:      return pointOnRect(for: .leadingTop)
        case .topRight:     return pointOnRect(for: .trailingTop)
        case .bottomLeft:   return pointOnRect(for: .leadingBottom)
        case .bottomRight:  return pointOnRect(for: .trailingBottom)
        }
    }
    
    var extremeCornerForCurrentQuadrant : CGPoint {
        return extremeCornerForQuadrant(self.quadrent)
    }
}
