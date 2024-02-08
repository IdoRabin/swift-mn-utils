//
//  ImageString.swift
//  Bricks
//
// Created by Ido Rabin for Bricks on 17/1/2024.

#if os(OSX)
    import AppKit
    import Cocoa
    public typealias SysImage = NSImage
    public typealias SysColor = NSColor
#elseif os(iOS)
    import UIKit
    public typealias SysImage = UIImage
    public typealias SysColor = UIColor
#endif

public class PlaceholderImage : SysImage {
    public convenience init?(named name: String) {
        guard let image = SysImage(named: name), let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage, size:image.size)
    }
}


/// Container for a string that can translate to a UIImage or MNImage (depending on the platform)
/// The container will be able
public struct ImageString {
    let rawValue : String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public func systemSymbolImage(accessibilityDescription:String?)->SysImage {
        return NSImage(systemSymbolName: rawValue, accessibilityDescription: nil)!
    }
    
    public var systemSymbolImage : SysImage {
        get {
            // NOTE: This will crash if string is an asset name
            return SysImage(systemSymbolName: rawValue, accessibilityDescription: nil)!
        }
    }
    
    public var image : SysImage {
        get {
            // NOTE: This will crash if string is a system symbol name
            return SysImage(named:self.rawValue)!
        }
    }
    
    public var placeholderImage : PlaceholderImage {
        get {
            return PlaceholderImage(named:self.rawValue)!
        }
    }
    
    public func imageTinted(_ color:NSColor)->NSImage {
        return self.image.tinted(color)!
    }
    
    public func imageScaled(_ scale:CGFloat)->NSImage {
        return self.image.scaled(scale)!
    }
    
    public func image(scale:CGFloat, tintColor:NSColor)->NSImage {
        return self.image.scaled(scale)!.tinted(tintColor)!
    }
}
