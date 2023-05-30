//
//  CGPointEx.swift
//  grafo
//
//  Created by Ido on 09/01/2023.
//

import Cocoa

extension CGPoint {
    
    
    /// Retutns a point offset on the x axis
    ///
    /// - Parameter xAdd: value to add to the x value
    /// - Returns: a new point with its x value offset by xAdd amount
    func offsetX(_ xAdd:CGFloat)->CGPoint {
        return CGPoint(x: self.x + xAdd, y: self.y)
    }
    
    /// Retutns a point offset on the y axis
    ///
    /// - Parameter xAdd: value to add to the y value
    /// - Returns: a new point with its y value offset by yAdd amount
    func offsetY(_ yAdd:CGFloat)->CGPoint {
        return CGPoint(x: self.x, y: self.y + yAdd)
    }
    
    /// Retutns a point offset on the x and y axis
    ///
    /// - Parameter xAdd: value to add to the x value
    /// - Parameter yAdd: value to add to the y value
    /// - Returns: a new point with its x and y values offset by xAdd and yAdd amounts
    func offset(xAdd:CGFloat, yAdd:CGFloat)->CGPoint {
        return CGPoint(x: self.x + xAdd, y: self.y + yAdd)
    }
    
    
    /// Returns a point with its x value changed to a new given value
    ///
    /// - Parameter xSet: new x value to set
    /// - Returns: a new point with its x value set with the given x paramemter
    func changed(x xSet:CGFloat)->CGPoint {
        return CGPoint(x: xSet, y: self.y)
    }
    
    /// Returns a point with its y value changed to a new given value
    ///
    /// - Parameter ySet: new y value to set
    /// - Returns: a new point with its y value set with the given y paramemter
    func changed(y ySet:CGFloat)->CGPoint {
        return CGPoint(x: self.x, y: ySet)
    }
    
    func rectAroundCenter(width:CGFloat, height:CGFloat)->CGRect {
        return CGRect(x: self.x - width * 0.5,
                      y: self.y - height * 0.5,
                      width: width,
                      height: height)
    }
    
    
    func asCGSize()->CGSize {
        return CGSize(width: self.x, height: self.y)
    }
    
    
    /// Retruns the squared distance between two points. i.e the Pythagorean theorem, but before applying the square root.
    /// - Parameter other: other point to calculate distance to
    /// - Returns: distance between the points, squared
    func distanceSqr(to other: CGPoint)->CGFloat {
        let dx = self.x - other.x
        let dy = self.y - other.y
        if dx == 0 && dy == 0 {
            return 0
        }
        return (dx * dx) + (dy * dy)
    }
    
    
    /// Returns the distance between the two points. Uses the the Pythagorean theorem.
    /// - Parameter other: other point to calculate distance to
    /// - Returns: distance between the points
    func distance(to other: CGPoint)->CGFloat {
        let dx = self.x - other.x
        let dy = self.y - other.y
        if dx == 0 && dy == 0 {
            return 0
        }
        return sqrt((dx * dx) + (dy * dy))
    }
}
