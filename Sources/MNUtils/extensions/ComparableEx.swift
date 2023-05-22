//
//  BaseUIClassesEx.swift
//  Bricks
//
//  Created by Ido Rabin on 17/01/2023.
//  Copyright © 2018 Bricks. All rights reserved.
//

import Cocoa
import Foundation


// The file adds convenience methods to CGRect, CGSize and CGPoint

/// Clamp function for comperables
///
/// - Parameters:
///   - value: value to be clamped
///   - lowerlimit: the lower limit for the value to be clamped by, if value is smaller (<) than the lower limit, the result will be the lower limit
///   - upperlimit: the upper limit for the value to be clamped by, if value is bigger (>) than the upper limit, the result will be the upper limit
/// - Returns: the value itself, or if bigger or smaller than the limits, the respective limit
public func clamp<T:Comparable>(value:T, lowerlimit:T, upperlimit:T, outOfBounds:((T)->Void)? = nil)->T {
    if let outOfBounds = outOfBounds, value < lowerlimit || value > upperlimit {
        outOfBounds(value)
    }
    return min(max(value, lowerlimit), upperlimit)
}
