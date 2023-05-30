//
//  CGSizeEx.swift
//  grafo
//
//  Created by Ido on 09/01/2023.
//

import Cocoa

extension CGSize {
    
    var aspectRatio: CGFloat {
        get {
            var hgt : CGFloat = self.height
            if hgt == 0.0 {hgt = 0.0001}
            return self.width / hgt
        }
    }
    
    /// Returns the center point of the rectangle. Equivalent to CGPoint(x: self.midX, y: self.midY)
    var center : CGPoint {
        return CGPoint(x: self.width / 2.0, y: self.height / 2.0)
    }
    
    /// Returns a mutated version of the size, updating all parameters that are not nil
    ///
    /// - Parameters:
    ///   - width: new width value, pass nil to keep old value
    ///   - height: new height value, pass nil to keep old value
    /// - Returns: a mutated size, having set all provided params that were not nil
    func changed(width setW:CGFloat? = nil, height setH:CGFloat? = nil)->CGSize {
        var result : CGSize = self

        if let setW = setW {
            result.width = setW
        }
        if let setH = setH {
            result.height = setH
        }
        
        return result
    }
    
    /// Returns a mutated version of the size, updating the width
    ///
    /// - Parameters:
    ///   - width: new width value, pass nil to keep old value
    /// - Returns: a mutated size, having set a new width
    func changed(width setW:CGFloat)->CGSize {
        var result : CGSize = self
        result.width = setW
        return result
    }
    
    /// Returns a mutated version of the size, updating the height
    ///
    /// - Parameters:
    ///   - height: new height value, pass nil to keep old value
    /// - Returns: a mutated size, having set a new height
    func changed(height setH:CGFloat)->CGSize {
        var result : CGSize = self
        result.height = setH
        return result
    }
    
    /// Returns a mutated version of the size, adding all parameters that are not nil
    ///
    /// - Parameters:
    ///   - widthAdd: delta to add to new size.width value, pass nil to keep old value
    ///   - heightAdd: delta to add to new size.height value, pass nil to keep old value
    /// - Returns: a mutated size, having added the value to all provided params that were not nil
    func adding(widthAdd:CGFloat? = nil, heightAdd:CGFloat? = nil)->CGSize {
        var result : CGSize = self
        if let widthAdd = widthAdd {
            result.width += widthAdd
        }
        if let heightAdd = heightAdd {
            result.height += heightAdd
        }
        return result
    }
    
    /// Returns a mutated version of the size, adding to its width
    ///
    /// - Parameters:
    ///   - widthAdd: delta to add to new size.width value, pass nil to keep old value
    /// - Returns: a mutated size, having added the value to the width
    func adding(widthAdd:CGFloat)->CGSize {
        var result : CGSize = self
        result.width += widthAdd
        return result
    }
    
    /// Returns a mutated version of the size, adding to its height
    ///
    /// - Parameters:
    ///   - heightAdd: delta to add to new size.width value, pass nil to keep old value
    /// - Returns: a mutated size, having added the value to the height
    func adding(heightAdd:CGFloat)->CGSize {
        var result : CGSize = self
        result.height += heightAdd
        return result
    }
    
    func rounded()->CGSize {
        var result : CGSize = self
        result.height = Darwin.round(self.height)
        result.width = Darwin.round(self.width)
        return result
    }
    
    func floored()->CGSize {
        var result : CGSize = self
        result.height = Darwin.floor(self.height)
        result.width = Darwin.floor(self.width)
        return result
    }
    
    func ceiled()->CGSize {
        var result : CGSize = self
        result.height = Darwin.ceil(self.height)
        result.width = Darwin.ceil(self.width)
        return result
    }
    
    func zeroOriginRect()->CGRect {
        return CGRect(origin: CGPoint.zero, size: self)
    }
}

// Aspect sizes:
extension CGSize {
    
    /// Returns the width / height aspect ratio
    
    func aspectFit(inside boundingSize: CGSize) -> CGSize {
        return CGSize.aspectFit(aspectRatio: self, boundingSize: boundingSize)
    }
    
    func aspectFill(inside minimumSize: CGSize) -> CGSize {
        return CGSize.aspectFill(aspectRatio: self, minimumSize: minimumSize)
    }
    
    static func aspectFit(aspectRatio : CGSize, boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        var result :CGSize = boundingSize
        
        if( mH < mW ) {
            result.width = result.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW < mH ) {
            result.height = result.width / aspectRatio.width * aspectRatio.height;
        }
        
        return result;
    }
    
    static func aspectFill(aspectRatio :CGSize, minimumSize: CGSize) -> CGSize {
        let mW = minimumSize.width / aspectRatio.width;
        let mH = minimumSize.height / aspectRatio.height;
        var result :CGSize = minimumSize
        
        if( mH > mW ) {
            result.width = result.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW > mH ) {
            result.height = result.width / aspectRatio.width * aspectRatio.height;
        }
        
        return result;
    }
    
    func scaled(_ multiplier:CGFloat)->CGSize {
        return CGSize(width: self.width * multiplier, height: self.height * multiplier)
    }
    
    func asCGPoint()->CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}

