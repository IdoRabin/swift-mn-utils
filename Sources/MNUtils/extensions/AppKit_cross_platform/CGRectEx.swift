//
//  CGRectEx.swift
//  grafo
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Cocoa
import CoreGraphics

extension CGRect {
    
    var aspectRatio: CGFloat {
        get {
            return self.size.aspectRatio
        }
    }
    
    init(boundsOf frame:CGRect) {
        self.init(origin: CGPoint.zero, size: frame.size)
    }
    
    func boundsRect()->CGRect {
        return CGRect(boundsOf: self)
    }
    
    func lerp(_ targetRect:CGRect, progress:Float)->CGRect {
        let part = CGFloat(min(max(progress, 0.0), 1.0))
        let inverse = 1.0 - part
        
        var result = self
        result.origin.x = (self.origin.x * inverse) + (targetRect.origin.x * part)
        result.origin.y = (self.origin.y * inverse) + (targetRect.origin.y * part)
        result.size.height = (self.size.height * inverse) + (targetRect.size.height * part)
        result.size.width = (self.size.width * inverse) + (targetRect.size.width * part)
        
        return result
    }
    
    mutating func inset(by:NSEdgeInsets) {
        self = self.insetted(by: by)
    }
    
    func insetted(by:NSEdgeInsets)->CGRect {
        return self.changed(x: by.left, y: by.top,
                            width: self.width - (by.left + by.right),
                            height: self.height - (by.top + by.bottom))
    }
    
    
    /// Returns the biggest bounded square (equal sisded rectanlge) that fits (is bounded by) in self rectangle, the returned square has its center at the bound rext's center.
    /// - Returns: biggect bounded square, centered
    func boundedSquare() -> CGRect {
        let minSze = min(self.width, self.height)
        if self.width > self.height {
            return CGRect(x: self.origin.x + (self.width - minSze) / 2.0,
                          y: self.origin.y,
                          width: minSze,
                          height: minSze)
        } else if self.width < self.height {
            return CGRect(x: self.origin.x,
                          y: self.origin.y + (self.height - minSze) / 2.0,
                          width: minSze,
                          height: minSze)
        }
        return self
    }
    
    /// Returns the smallest bounding square (equal sided rectanle) that can fit (bounds) the self rectangle. The returned square ahs the same center as teh bound rect's center;
    /// - Returns: smaller bounding square, centerd
    func boundingSquare() -> CGRect {
        let maxSze = max(self.width, self.height)
        if self.width < self.height {
            return CGRect(x: self.origin.x + (self.width - maxSze) / 2.0, y: self.origin.y, width: maxSze, height: maxSze)
        } else if self.width > self.height {
            return CGRect(x: self.origin.x, y: self.origin.y + (self.height - maxSze) / 2.0, width: maxSze, height: maxSze)
        }
        return self
    }
    
    func settingNewCenter(_ newCenter : CGPoint)->CGRect {
        var result = self
        result.origin.x = newCenter.x - (self.width * 0.5)
        result.origin.y = newCenter.y - (self.height * 0.5)
        return result
    }

    
    /// Returns the center point of the rectangle. Equivalent to CGPoint(x: self.midX, y: self.midY)
    var center : CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    /// Returns a mutated version of the rect, updating all parameters that are not nil
    ///
    /// - Parameters:
    ///   - x: new origin.x value, pass nil to keep old value
    ///   - y: new origin.y value, pass nil to keep old value
    ///   - width: new size.width value, pass nil to keep old value
    ///   - height: new size.height value, pass nil to keep old value
    /// - Returns: a mutated rect, having set all provided params that were not nil
    func changed(x setX:CGFloat? = nil, y setY:CGFloat? = nil, width setW:CGFloat? = nil, height setH:CGFloat? = nil)->CGRect {
        var result : CGRect = self
        if let setX = setX {
            result.origin.x = setX
        }
        if let setY = setY {
            result.origin.y = setY
        }
        
        if let setW = setW {
            result.size.width = setW
        }
        if let setH = setH {
            result.size.height = setH
        }
        
        return result
    }
    
    /// Returns a mutated version of the rect, updating origin.x to a new value
    ///
    /// - Parameters:
    ///   - x: new origin.x value
    /// - Returns: a mutated copy of the original rect, with a mutated x value
    func changed(x setX:CGFloat)->CGRect {
        var result : CGRect = self
        result.origin.x = setX
        return result
    }
    
    /// Returns a mutated version of the rect, updating origin.y to a new value
    ///
    /// - Parameters:
    ///   - y: new origin.y value
    /// - Returns: a mutated copy of the original rect, with a mutated y value
    func changed(y setY:CGFloat)->CGRect {
        var result : CGRect = self
        result.origin.y = setY
        return result
    }
    
    /// Returns a mutated version of the rect, updating size.height to a new value
    ///
    /// - Parameters:
    ///   - height: new size.height value
    /// - Returns: a mutated copy of the original rect, with a mutated height value
    func changed(height setHeight:CGFloat)->CGRect {
        var result : CGRect = self
        result.size.height = setHeight
        return result
    }
    
    /// Returns a mutated version of the rect, updating size.width to a new value
    ///
    /// - Parameters:
    ///   - width: new size.width value
    /// - Returns: a mutated copy of the original rect, with a mutated width value
    func changed(width setWidth:CGFloat)->CGRect {
        var result : CGRect = self
        result.size.width = setWidth
        return result
    }
    
    /// Returns a mutated version of the rect, adding all parameters that are not nil
    ///
    /// - Parameters:
    ///   - xAdd: delta to add to new origin.x value, pass nil to keep old value
    ///   - yAdd: delta to add to new origin.y value, pass nil to keep old value
    ///   - widthAdd: delta to add to new size.width value, pass nil to keep old value
    ///   - heightAdd: delta to add to new size.height value, pass nil to keep old value
    /// - Returns: a mutated rect, having added the value to all provided params that were not nil
    func adding(xAdd:CGFloat? = nil, yAdd:CGFloat? = nil, widthAdd:CGFloat? = nil, heightAdd:CGFloat? = nil)->CGRect {
        var result : CGRect = self
        if let xAdd = xAdd {
            result.origin.x += xAdd
        }
        if let yAdd = yAdd {
            result.origin.y += yAdd
        }
        if let widthAdd = widthAdd {
            result.size.width += widthAdd
        }
        if let heightAdd = heightAdd {
            result.size.height += heightAdd
        }
        
        return result
    }
    
    /// Returns a mutated version of the rect, adding a delta value to the current origin.x value
    ///
    /// - Parameters:
    ///   - xAdd: delta to add to the current origin.x value
    /// - Returns: a mutated copy of the original rect, with a mutated x value (delta added)
    func adding(xAdd:CGFloat)->CGRect {
        var result : CGRect = self
        result.origin.x += xAdd
        return result
    }
    
    /// Returns a mutated version of the rect, adding a delta value to the current origin.y value
    ///
    /// - Parameters:
    ///   - yAdd: delta to add to the current origin.y value
    /// - Returns: a mutated copy of the original rect, with a mutated y value (delta added)
    func adding(yAdd:CGFloat)->CGRect {
        var result : CGRect = self
        result.origin.y += yAdd
        return result
    }
    
    /// Returns a mutated version of the rect, adding a delta value to the current size.width value
    ///
    /// - Parameters:
    ///   - widthAdd: delta to add to the current size.width value
    /// - Returns: a mutated copy of the original rect, with a mutated width value (delta added)
    func adding(widthAdd:CGFloat)->CGRect {
        var result : CGRect = self
        result.size.width += widthAdd
        return result
    }
    
    /// Returns a mutated version of the rect, adding a delta value to the current size.height value
    ///
    /// - Parameters:
    ///   - height: delta to add to the current size.height value
    /// - Returns: a mutated copy of the original rect, with a mutated height value (delta added)
    func adding(heightAdd:CGFloat)->CGRect {
        var result : CGRect = self
        result.size.height += heightAdd
        return result
    }
    
    
    /// Inset the rectangle but return zero sizes if inset will have returned a null rect or negative values
    ///
    /// - Parameters:
    ///   - dx: x dimension to inset from both sides of rect. if dx > rect.width / 2.0, will return a rect with width zero.
    ///   - dy: y dimension to inset from both sides of rect. if dy > rect.height / 2.0, will return a rect with height zero.
    /// - Returns: returned inset rect, where measurments will always be >= 0.0
    func insetToZero(dx: CGFloat, dy: CGFloat)->CGRect {
        return self.insetBy(dx:((dx > self.width / 2.0) ? (self.width / 2.0) :  dx), dy:((dy > self.height / 2.0) ? (self.height / 2.0) :  dy))
    }
    
    /// Returns a rectangle that is scaled to a multiplier of the original rectange, keeping its center
    /// - Parameter xscale: multipleir for scale of width
    /// - Parameter yscale: multipleir for scale of height
    func scaledAroundCenter(_ xscale:CGFloat, _ yscale : CGFloat) -> CGRect {
        let xInset = (self.width - (self.width * xscale)) / 2.0
        let yInset = (self.height - (self.height * yscale)) / 2.0
        return self.insetBy(dx:xInset, dy: yInset)
    }
    
    var debugIntDescription : String {
        //(575.0, 159.0, 29.0, 16.0)
        return "(\(Int(self.origin.x)),\(Int(self.origin.y)),\(Int(self.size.width)),\(Int(self.size.height)))"
    }
    /// Will offset / add point to rectangle
    /// The width and height do not hchange, and the x and y are results of adding the corresponding values from point to the orgiginal ones.
    /// - Parameter point: point to offset.
    func offset(by point:CGPoint)->CGRect {
        var result : CGRect = self
        result.origin.x += point.x
        result.origin.y += point.y
        return result
    }
    
    func scaledFromOrigin(_ xscale:CGFloat, _ yscale : CGFloat) -> CGRect {
        return CGRect(x: self.origin.x * xscale,
                      y: self.origin.y * yscale,
                      width: self.width * xscale,
                      height: self.height * yscale)
    }
    
    
    /// Will make the width and height of the rectangle grow, keeping the center of the rectangle atthe same location, hence, the x and y origin will move by -0.5 grow size too.
    /// - Parameters:
    ///   - widthAdd: width to add to the current rect width
    ///   - heightAdd: height to add to the current rect height
    /// - Returns: a rectangle with the width enlarged by widthAdd and height enlarged by heightAdd, sharing the same center as the original rect
    func growAroundCener(widthAdd:CGFloat, heightAdd : CGFloat) -> CGRect {
        return CGRect(x: self.origin.x - widthAdd*0.5,
                      y: self.origin.y - heightAdd*0.5,
                      width: self.width + widthAdd,
                      height: self.height + heightAdd)
    }
    
    /// Scales the sizes of the rectangle by given multipliers without changing the origin
    /// - Parameters:
    ///   - mulW: multiplier for the width size
    ///   - mulH: multiplier for the height size
    /// - Returns: a mutated rectangle whose sizes were multiplied by the given parameters, whilst the origin is unchanged
    func scaledSizes(mulW:CGFloat? = nil, mulH:CGFloat? = nil)->CGRect {
        var result : CGRect = self

        if let mulW = mulW {
            result.size.width *= mulW
        }
        
        if let mulH = mulH {
            result.size.height *= mulH
        }
        
        return result
    }
    
    
    /// Scales the width of the rectangle by given multiplier without changing the origin or the height
    /// - Parameter mulW: multiplier for the width size
    /// - Returns: a mutated rectangle whose width was multiplied by the given parameter
    func scaledWidth(_ mulW:CGFloat)->CGRect {
        var result : CGRect = self
        
        result.size.width *= mulW

        return result
    }
    
    /// Scales the height of the rectangle by given multiplier without changing the origin or the width
    /// - Parameter mulW: multiplier for the height size
    /// - Returns: a mutated rectangle whose height was multiplied by the given parameter
    func scaledHeight(_ mulH:CGFloat)->CGRect {
        var result : CGRect = self
        
        result.size.height *= mulH
        
        return result
    }
    
    /// Returns a copy of the rectangle where x,y and sizes are rounded.
    func rounded()->CGRect {
        
        return CGRect(x: round(self.origin.x),
                      y: round(self.origin.y),
                      width: round(self.size.width),
                      height: round(self.size.height))
    }
    
    /// Returns a copy of the rectangle where x,y and sizes are rounded to the x digit after the decimal point.
    func rounded(toDecimal num_places:Int)->CGRect {
        let prec : CGFloat = CGFloat(pow(10.0, CGFloat(max(num_places, 0))));
        return CGRect(x: round(self.origin.x * prec) / prec,
                      y: round(self.origin.y * prec) / prec,
                      width: round(self.size.width * prec) / prec,
                      height: round(self.size.height * prec) / prec)
    }
}

extension CGRect { /* Aspect sizes */
    
    /// Returns the width / height aspect ratio
    
    
    /// Returns a rect that best fits inside the given bouning rect, keeping the aspect ratio of self
    /// - Parameter boundingRect: rect that is the bounding rect for the currec rect's aspect ratio
    /// - Returns: a new rect bounded by the given bounding rect keeping the self's aspect ratio
    func aspectFit(rect boundingRect: CGRect) -> CGRect {
        return self.aspectFitting(inside: boundingRect)
    }
    
    
    /// Returns a rect that best fills the given bouning rect, keeping the aspect ratio of self
    /// - Parameter boundingRect:  rect that is the bounding rect for the currec rect's aspect ratio
    /// - Returns: a new rect that fills the bounds of the given bounding rect, keeping the self's aspect ratio
    func aspectFill(rect boundingRect: CGRect) -> CGRect {
        return boundingRect.aspectFilling(inside: self)
    }
    
    func aspectFitting(inside boundingRect: CGRect) -> CGRect {
        let sze = CGSize.aspectFit(aspectRatio: self.size, boundingSize: boundingRect.size)
        return CGRect(origin: CGPoint(x: (self.width - sze.width) * 0.5,
                                      y: (self.height - sze.height) * 0.5),
                                        size: sze)
    }
    
    func aspectFilling(inside boundingRect: CGRect) -> CGRect {
        let sze = CGSize.aspectFill(aspectRatio: self.size, minimumSize: boundingRect.size)
        return CGRect(origin: CGPoint(x: (self.width - sze.width) * 0.5,
                                      y: (self.height - sze.height) * 0.5),
                                        size: sze)
    }
    
    
    /// Will move the self rectangel the minimum amount of offset to fit into ththe given bounding rect
    /// NOTE: if the bounding rect is smaller in height or width than self, will return self unchanged
    /// if the bounding rect does not even intersect with self, we return self
    /// - Parameter boundingRect: the rectangle to be bounded by
    /// - Returns: a rectangle that fits inside the boundingRect without intersection, or self
    func bumpInside(boundingRect:CGRect)->CGRect {
        if boundingRect.contains(self) {
            // No need to bump the rectangle inside the bounding rect, it is already wholly contained in it
            return self
            
        } else if boundingRect.intersects(self) {
            // Self intersects with the bounding box
            
            var offset = CGPoint.zero
            
            if self.width > boundingRect.width {
                offset.x = boundingRect.center.x - self.center.x
            } else if self.maxX > boundingRect.maxX {
                offset.x = -(self.maxX - boundingRect.maxX)
            } else if self.minX < boundingRect.minX {
                offset.x = +(boundingRect.minX - self.minX)
            }
            
            if self.height > boundingRect.height {
                offset.y = boundingRect.center.y - self.center.y
            } else if self.maxY > boundingRect.maxY {
                offset.y = -(self.maxY - boundingRect.maxY)
            } else if self.minY < boundingRect.minY {
                offset.y = +(boundingRect.minY - self.minY)
            }
            
            return self.offset(by: offset)
            
        } else {
            // Self is completely outside of the area of out rect
            return self
        }
    }
    
    func rightHandDirectionalized()->CGRect {
        var result = self
        if result.size.width < 0 {
            result.origin.x -= result.width
            result.size.width = result.width
        }
        if result.size.height < 0 {
            result.origin.y -= result.height
            result.size.height = result.height
        }
        return result
    }
    
}

extension CGSize : @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
    
    var isZero : Bool {
        return self.width == 0 && self.height == 0
    }
}

extension CGPoint : @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}

extension CGRect : @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.origin)
        hasher.combine(self.size)
    }
}

extension NSEdgeInsets {
    static var zero : NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    var isZero : Bool {
        return top == 0 && left == 0 && bottom == 0 && right == 0
    }
    
    init(allSides:CGFloat) {
        self.init(top: allSides, left: allSides, bottom: allSides, right: allSides)
    }
}
