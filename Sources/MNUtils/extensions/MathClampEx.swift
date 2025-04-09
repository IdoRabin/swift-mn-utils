//
//  MathEx.swift
//  Knowz
//
//  Created by ido on 30/06/2024.
//

import Foundation

public enum CompErrors : Error, DisplayStringable {
    case minGreaterThanMax
    
    public var displayString : DisplayString {
        switch self {
        case .minGreaterThanMax:
            return "Minimum value is greater than maximum value!"
        }
    }
}

extension CompErrors : MNErrorable {
    public var desc: String {
        self.description
    }
    
    public var domain: String {
        "MNUtils.MathClampEx"
    }
    
    public var reason: String {
        self.displayString
    }
    
    public var code : MNErrorInt { MNErrorCode.misc_failed_validation.code  }
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
    
    func clamped(min amin:Self, max amax:Self) throws -> Self {
        if (amin > amax) {
            throw CompErrors.minGreaterThanMax
        }
        return min(max(self, amin), amax)
    }
}

public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
    return min(max(value, minValue), maxValue)
}
