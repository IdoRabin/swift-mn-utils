//
//  UIImage+Utils.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.
// Copyright © 2024 Bricks. All rights reserved.
//

import Foundation

#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

#if os(OSX)
import Cocoa
import AppKit

extension NSImage {
    
    @available(macOS 11.0, *)
    static func systemSymbol(named systemSymbolName:String, pointSize:CGFloat = 16, weight:NSFont.Weight = .regular, accessibilityDescription:String?)->NSImage? {
        let image = self.init(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return image?.withSymbolConfiguration(config)
    }
    
    
    @objc var cgImage: CGImage? {
        get {
            guard let imageData = self.tiffRepresentation else { return nil }
            guard let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
        }
    }
    
    /// Returns a copy of an image with a new alpha value for all pixels
    ///
    /// - Parameter value: alpha value (clamped to the range of [0.0...1.0]
    /// - Returns: a new image with the given alpha
    func alpha(_ value:CGFloat) -> NSImage {
        assert(false, "TODO: Implement NSImage copy with alpha")
        return NSImage.init()
    }
    
    /// Returns a tinted copy for a given image
    ///
    /// - Parameter color: target tint color
    /// - Returns: a tinted UIImage replication for self, or nil if failed
    func tinted(_ tintColor:NSColor)->NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }

        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)

            return true
        }
    }
    
    
    /// Returns the image as a greyscale version of the original
    /// The function uses Noir greyscale
    ///
    /// - Returns: a greyscale image
    func greyscale()->NSImage? {
        let existingRep = NSBitmapImageRep(cgImage: self.cgImage!)
        if let newRep = existingRep.converting(to: .genericGray, renderingIntent: .default) {
            let newImg = NSImage(size: self.size)
            newImg.addRepresentation(newRep)
            return newImg
        }
        return nil
    }
    
    /// Returns an image flipped on the x or y or both axis
    ///
    /// - Parameters:
    ///   - x: should flip on x axis
    ///   - y: should flip on y axis
    /// - Returns: an image flipped on the requested axis
    func flipped(x:Bool, y:Bool)->NSImage {
        assert(false, "TODO: Implement NSImage copy flipped")
        return NSImage()
    }
    
    /// Returns an image flipped on the x axis
    ///
    /// - Parameters:
    ///   - x: should flip on x axis
    /// - Returns: an image flipped on the requested axis
    func flipped(x:Bool)->NSImage {
        return self.flipped(x: x, y: false)
    }
    
    /// Returns an image flipped on the y axis
    ///
    /// - Parameters:
    ///   - y: should flip on y axis
    /// - Returns: an image flipped on the requested axis
    func flipped(y:Bool)->NSImage {
        return self.flipped(x: false, y: y)
    }
    
    /// Returns an image resized (keeps aspect ratio) that occupies the given width exactly
    ///
    /// - Parameter newWidth: the width for the new image
    /// - Returns: new image that has the new width, and height that keeps original's aspect ratio
    func resizedToFit(width newWidth: CGFloat) -> NSImage? {
        
        assert(false, "TODO: Implement NSImage copy with resizedToFit:newWidth")
        return nil
    }
    
    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
    func resize(stretchingToSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }
    
    /// Returns an image resized (keeps aspect ratio) that occupies the given height exactly
    ///
    /// - Parameter newHeight: the height for the new image
    /// - Returns: new image that has the new height, and width that keeps original's aspect ratio
    func resizedToFit(height newHeight: CGFloat) -> NSImage? {
        assert(false, "TODO: Implement NSImage copy with resizedToFit:newHeight")
        return nil
    }
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size
    /// - Parameter size: size to fit the image into
    func resizedToFit(boundingSize: CGSize) -> NSImage? {
        return self.scaledToFit(boundingSize: boundingSize)
    }
    
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size
    /// - Parameter boundingSize: size to fit the image NSImage
    func scaledToFit(boundingSize: CGSize) -> NSImage? {
        var scale : CGFloat = boundingSize.width  / self.size.width
        scale = min(scale, boundingSize.height  / self.size.height)
        
        if scale != 1.0 {
            if let img = self.scaledByAxis(xscale: scale, yscale: scale) {
                return img
            }
        }
        return self
        
    }
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size (aspect fit to size that is both width and height of the given boundingSize)
    /// - Parameter size: size to fit the image into
    func scaledToFit(boundingSizes: CGFloat) -> NSImage? {
        return self.scaledToFit(boundingSize: CGSize(width: boundingSizes, height: boundingSizes))
    }
    
    /// Returns an image resized to the given scale, keeping aspect ratio
    /// scale is clamped betweeen > 0.0001 and < 1000.0, where 1.0 is the original scale, scale < 1.0 makes the image smaller than the original, and scale > 1.0 makes it bigger than original
    /// - Parameter scale: scale
    /// - Returns: an image scaled to the given multiplier, keeping the original's aspect ratio
    func scaled(_ scale:CGFloat = 1.0)->NSImage? {
        guard scale != 1.0 else {
            return self
        }
        let sze = self.size.scaled(scale).rounded()
        return self.resize(stretchingToSize: sze)
    }
    
    
    /// Returns an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    /// both scale parameters are clamped betweeen > 0.0001 and < 1000.0, where 1.0 is the original scale, scale < 1.0 makes the image smaller than the original on that axis, and scale > 1.0 makes it bigger than original on that axis
    ///
    /// - Parameters:
    ///   - xscale: scale to multiply the width
    ///   - yscale: scale to multiply the height
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func scaledByAxis(xscale:CGFloat = 1.0, yscale:CGFloat = 1.0)->NSImage? {
        guard xscale != 1.0 || yscale != 1.0 else {
            return self
        }
        
        let newSize = CGSize(width: self.size.width * xscale, height: self.size.height * yscale)
        return self.resize(stretchingToSize: newSize)
    }
    
    
    /// Returns an image cropped using the given insets, having the original image NOT change size or scale and drawn inside the new image
    /// both inset parameters may be negative or positive, and indicate the insets with which the image size will be changed in each direction. That is, xInset will be subtracted on the left AND right side, and yInset will be subtracted on the top and bottom. The total size (width/height) change is twice the inset size's negative. Positive insets will crop (make image smaller), and negative insets will pad the image with transparent padding.
    /// both inset parameters are clamped betweeen > -1000.0 and < 1000.0. An image will not be cropped to a size smaller than 1 pixel in both aspects. In such cases, nil will be returned.
    ///
    /// - Parameters:
    ///   - xInset: inset by which to crop the image's height (negative value will pad the image with transparent bkg, enlarging its height)
    ///   - yInset: inset by which to crop the image's width (negative value will pad the image with transparent bkg, enlarging its wisth)
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func croppedByInsets(xInset:CGFloat = 0.0, yInset:CGFloat = 1.0, xoffset:CGFloat = 0.0, yoffset:CGFloat = 0.0)->NSImage? {
        return self.cropped(area: self.size.zeroOriginRect().insetBy(dx: xInset, dy: yInset).offsetBy(dx: xoffset, dy: yoffset))
    }
    
    
    
    /// Returns a segment of the original image cropped to a given rect
    /// - Parameters:
    ///   - area: rectangle of the area to be cropped (this area will be returned)
    ///   - flipY: flip the y measurements in case we are using some flipped up stuff
    func cropped(area: CGRect, flipY:Bool = false) -> NSImage? {
        guard let cgimg = self.cgImage else {
            return nil
        }
        
        var rect = area
        if flipY {
            rect.origin.y = CGFloat(cgimg.height) - rect.origin.y - rect.size.height
        }
        if let newCGImg = cgimg.cropping(to: rect) {
            let image = NSImage(cgImage: newCGImg, size: rect.size)
            return image
        }
        
        return nil

    }
    
    /// Returns an image padded / enlareged w/ transparent padding to the given insets, having the original image NOT change size or scale inside the new image
    /// both padding parameters may be negative or positive, and indicate the padding with which the image size will be changed in each direction. That is, xPadding will be added on the left AND right side, and yPadding will be added on the top and bottom. The total size (width/height) change is twice the inset size. Positive paddings  will pad the image with transparent padding. Negative paddings will crop (make image smaller).
    /// both padding parameters are clamped betweeen > -1000.0 and < 1000.0. An image will not be padded using negative values to a size smaller than 1 pixel in both aspects. In such cases, nil will be returned.
    ///
    /// - Parameters:
    ///   - xPadding: padding by which to pad the image's height (negative value will crop the image's width)
    ///   - yPadding: padding by which to pad the image's width (negative value will crop the image's width)
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func paddedWithPaddings(xPadding:CGFloat = 0.0, yPadding:CGFloat = 1.0, xoffset:CGFloat = 0.0, yoffset:CGFloat = 0.0)->NSImage? {
        return self.croppedByInsets(xInset:-xPadding, yInset:-yPadding, xoffset:xoffset, yoffset:yoffset)
    }
    
    func paddedWithPaddings(uniformSides allSides:CGFloat = 0.0)->NSImage? {
        return self.paddedWithPaddingEdges(insets: NSEdgeInsets(top: allSides, left: allSides, bottom: allSides, right: allSides))
    }
        
    func paddedWithPaddingEdges(top:CGFloat = 0.0, left:CGFloat = 1.0, bottom:CGFloat = 0.0, right:CGFloat = 0.0)->NSImage? {
        return self.paddedWithPaddingEdges(insets: NSEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    
    func paddedWithPaddingEdgeParts(top:CGFloat = 0.0, left:CGFloat = 1.0, bottom:CGFloat = 0.0, right:CGFloat = 0.0)->NSImage? {
        guard left > 0.0 && left < 1.0 else {
            return nil
        }
        guard bottom > 0.0 && bottom < 1.0 else {
            return nil
        }
        guard right > 0.0 && right < 1.0 else {
            return nil
        }
        guard top > 0.0 && top < 1.0 else {
            return nil
        }
        
        let w = self.size.width
        let h = self.size.height
        let edges = NSEdgeInsets(top: h * top, left: w * left, bottom: h * bottom, right: w * right)
        return self.paddedWithPaddingEdges(insets: edges)
    }

    func paddedWithPaddingEdges(insets:NSEdgeInsets)->NSImage? {
        let newWidth = max(self.size.width + (insets.left + insets.right), 0)
        let newHeight = max(self.size.height + (insets.top + insets.bottom), 0)
        if newWidth >= 1.0 && newHeight >= 1.0 {
            let newRect = CGRect(origin: .zero, size: CGSize(width: newWidth, height: newHeight))
            let imgRect = newRect.insetted(by: insets)
            guard let existingRep = self.bestRepresentation(for: imgRect.boundsRect(), context: nil, hints: nil) else {
                return nil
            }
            let newImg = NSImage(size: newRect.size, flipped: false, drawingHandler: { (_) -> Bool in
                return existingRep.draw(in: imgRect)
            })

            return newImg
        }
        



//        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
//            return representation.draw(in: frame)
//        })
        
        return nil
    }

    /// Create solid colored image with a given size
    ///
    /// - Parameters:
    ///   - color: color for the image
    ///   - size: size for the image
    public convenience init?(color: NSColor, size: CGSize = CGSize(width: 1, height: 1)) {
        assert(false, "TODO: Implement NSImage convenience init?(color: NSColor")
        return nil
    }
    
    /// Returns a gaussian blurred copy for a given image, with the same scale and sizes
    ///
    /// - Parameter redius: redius of blur
    /// - Returns: a tinted UIImage replication for self, or nil if failed
    func blurred(blurRadius:UInt)->NSImage? {
        
        assert(false, "TODO: Implement NSImage copy with blurred:blurRadius")
        return nil
    }
    
}

extension NSImage /* saving */ {
    
    /// A PNG representation of the image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }

        return nil
    }
    
    /// Save the images PNG representation the the supplied file URL:
    ///
    /// - Parameter url: The file URL to save the png file to.
    /// - Throws: An unwrappingPNGRepresentationFailed when the image has no png representation.
    func savePngTo(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        } else {
            throw NSImageExtensionError.unwrappingPNGRepresentationFailed
        }
    }
}

/// Exceptions for the image extension class.
///
/// - creatingPngRepresentationFailed: Is thrown when the creation of the png representation failed.
enum NSImageExtensionError: Error {
    case unwrappingPNGRepresentationFailed
}


extension NSImage /* +URL */{
    
    // MARK:- Error handling
    /// contains a LocalizedError for when the load image extentions fail.
    public struct LoadImageError: LocalizedError {
        private let message:String
        public init(_ message:String) {
            self.message = message
        }
        public var errorDescription: String? { get { return self.message } }
        public var failureReason: String? { get { return self.message } }
        public var recoverySuggestion: String? { get { return self.message } }
        public var helpAnchor: String? { get { return self.message } }
    }
    
    public static func loadImage( fromURL:URL, completionHandler: @escaping (_ image:NSImage?, _ error:LocalizedError?)->Void) {
        if fromURL.isFileURL {
            do {
                let data = try Data(contentsOf: fromURL)
                let result = NSImage(data: data) // NSScreen.main.scale ? ?
                completionHandler(result, nil)
            } catch let error as NSError {
                completionHandler(nil, LoadImageError("unable to convert data in url \(fromURL.path) to image. error:\(error.description)"))
            }
        } else {
            URLSession(configuration: .default)
                .dataTask(with: fromURL) { (data, response, error) in
                    if let error = error {
                        completionHandler(nil, LoadImageError(error.localizedDescription))
                        return
                    }
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode != 200 {
                            completionHandler(nil, LoadImageError("bad response \(response.statusCode) - \(response.description)"))
                            return
                        }
                        if let data = data {
                            if let image = NSImage(data: data) {
                                completionHandler(image, nil)
                                return
                            }
                            if response.mimeType?.contains("text") ?? false ||
                                response.mimeType?.contains("json") ?? false {
                                completionHandler(nil, LoadImageError("unable to convert data " + (String(data: data, encoding: .utf8) ?? "\(data)") + " to image"))
                                return
                            }
                            completionHandler(nil, LoadImageError("unable to convert data \(data) to image"))
                            return
                        }
                        completionHandler(nil, LoadImageError("unable to retrieve response data"))
                        return
                    }
                    completionHandler(nil, LoadImageError("unknown response type"))
                }.resume()
        }
    }
}

#elseif os(iOS)

extension UIImage {
    
    
    /// Returns a copy of an image with a new alpha value for all pixels
    ///
    /// - Parameter value: alpha value (clamped to the range of [0.0...1.0]
    /// - Returns: a new image with the given alpha
    func alpha(_ value:CGFloat) -> UIImage {
        let alpha = clamp(value: value, lowerlimit: 0.0, upperlimit: 1.0)
        UIGraphicsBeginImageContextWithOptions(self.size, /*opaque:*/ false, /*scale:*/self.scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    /// Returns a tinted copy for a given image
    ///
    /// - Parameter color: target tint color
    /// - Returns: a tinted UIImage replication for self, or nil if failed
    func tinted(_ color:UIColor)->UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(self.size, /*opaque:*/ false, /*scale:*/self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            // flip the image
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -self.size.height)
    
            
            // multiply blend mode
            context.setBlendMode(CGBlendMode.multiply)
            
            let rect = CGRect(x:0, y:0, width:self.size.width, height:self.size.height)
            context.clip(to: rect, mask: self.cgImage!)
            color.setFill()
            context.fill(rect)
            
            // create uiimage
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        return nil
    }
    
    
    func applyingAlphaGradient(fromAlpha:CGFloat = 0.0, toAlpha:CGFloat = 1.0, fromPoint:CGPoint = CGPoint(x: 0, y: 0.5), toPoint:CGPoint = CGPoint(x: 1.0, y: 0.5))->UIImage? {
        guard let image = CIImage(image: self) else {
            return nil
        }
        
        let ciContext = CIContext()
        
        // Construct a circle
        let gradient = CIFilter(_name: "CILinearGradient", parameters:[
            "inputPoint0":CIVector(cgPoint: CGPoint(x: fromPoint.x * self.size.width, y: (1.0 - fromPoint.y) * self.size.height)),
            "inputPoint1":CIVector(cgPoint: CGPoint(x: toPoint.x * self.size.width, y: (1.0 - toPoint.y) * self.size.height)),
            "inputColor0":CIColor(red: fromAlpha, green: fromAlpha, blue: fromAlpha, alpha:1),
            "inputColor1":CIColor(red: toAlpha, green: toAlpha, blue: toAlpha, alpha:1)
        ])?.outputImage
        
        // Turn the circle into an alpha mask
        let mask = CIFilter(_name: "CIMaskToAlpha", parameters: [kCIInputImageKey:gradient!])?.outputImage
        
        // Apply the mask to the input image
        let combine = CIFilter(_name: "CIBlendWithAlphaMask", parameters:[
            kCIInputMaskImageKey:mask!,
            kCIInputImageKey:image
        ])
        
        if let output = combine?.outputImage {
            let cgimg = ciContext.createCGImage(output, from: output.extent)
            let processedImage = UIImage(cgImage: cgimg!, scale:UIScreen.main.scale, orientation: self.imageOrientation)
            return processedImage
        }
        return nil
    }
    
    /// Returns the image as a greyscale version of the original
    /// The function uses Noir greyscale
    ///
    /// - Returns: a greyscale image
    func greyscale()->UIImage? {
        let ciContext = CIContext()
        let currentFilter = CIFilter(_name: "CIPhotoEffectNoir")
        currentFilter!.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = ciContext.createCGImage(output!,from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!, scale:UIScreen.main.scale, orientation: self.imageOrientation)
        return processedImage
    }
    
    /// Will turn the current image into grayscale and use the grayscale result as the mask for a single-colored image.
    /// - Parameter color: color for the resulting image
    /// - Returns: an image where the color is the given color and the alpha is dictated by the greyscale map of this self image
    func greyscaleAsMask(for color:UIColor = UIColor.orange)->UIImage? {
        let grey = self.greyscale()
        if let maskRef = grey?.cgImage, let image = UIImage(color: color, size: self.size) {
            let mask = CGImage(
                maskWidth: maskRef.width,
                height: maskRef.height,
                bitsPerComponent: maskRef.bitsPerComponent,
                bitsPerPixel: maskRef.bitsPerPixel,
                bytesPerRow: maskRef.bytesPerRow,
                provider: maskRef.dataProvider!,
                decode: nil,
                shouldInterpolate: false)
            
            let masked = image.cgImage!.masking(mask!)
            let maskedImage = UIImage(cgImage: masked!)
            
            // No need to release. Core Foundation objects are automatically memory managed.
            return maskedImage
        }

        return nil
    }
    
    func applyCIFilter(_ named : String?, setupIfPossible:(_ filter : CIFilter)->Void)->UIImage {
        if let fname = named, let filter = CIFilter(_name: fname) {
            let ciContext = CIContext()
            filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            setupIfPossible(filter)
            let output = filter.outputImage
            let cgimg = ciContext.createCGImage(output!,from: output!.extent)
            let processedImage = UIImage(cgImage: cgimg!, scale:UIScreen.main.scale, orientation: self.imageOrientation)
            return processedImage
        } else {
            NSLog("UIImage+Utils applyCIFilter failed to create filter named: \"%@\"", named ?? "<nil>" )
            return self
        }
    }
    
    /// Returns an image flipped on the x or y or both axis
    ///
    /// - Parameters:
    ///   - x: should flip on x axis
    ///   - y: should flip on y axis
    /// - Returns: an image flipped on the requested axis
    func flipped(x:Bool, y:Bool)->UIImage {
        
        if ((x == false && y == false) || self.cgImage == nil) {
            
            // no flip
            return self
            
        } else if (x == false && y == true) {
            
            // flip vertically
            return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: UIImage.Orientation.downMirrored)
            
        } else if (x == true && y == true) {
            
            // flip and mirror:
            return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: UIImage.Orientation.upMirrored)
            
        } else {
            
            // NOTE: CAN ALSO USE self.withHorizontallyFlippedOrientation
            
            // Another approach is:
            let img = UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: UIImage.Orientation.leftMirrored)
            return UIImage(cgImage: img.cgImage!, scale: 1.0, orientation: UIImage.Orientation.upMirrored)
        }
    }
    
    /// Returns an image flipped on the x axis
    ///
    /// - Parameters:
    ///   - x: should flip on x axis
    /// - Returns: an image flipped on the requested axis
    func flipped(x:Bool)->UIImage {
        return self.flipped(x: x, y: false)
    }
    
    /// Returns an image flipped on the y axis
    ///
    /// - Parameters:
    ///   - y: should flip on y axis
    /// - Returns: an image flipped on the requested axis
    func flipped(y:Bool)->UIImage {
        return self.flipped(x: false, y: y)
    }
    
    /// Returns an image resized (keeps aspect ratio) that occupies the given width exactly
    ///
    /// - Parameter newWidth: the width for the new image
    /// - Returns: new image that has the new width, and height that keeps original's aspect ratio
    func resizedToFit(width newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
        self.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    /// Returns an image resized (keeps aspect ratio) that occupies the given height exactly
    ///
    /// - Parameter newHeight: the height for the new image
    /// - Returns: new image that has the new height, and width that keeps original's aspect ratio
    func resizedToFit(height newHeight: CGFloat) -> UIImage? {
        
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
        self.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size
    /// - Parameter size: size to fit the image into
    func resizedToFit(boundingSize: CGSize) -> UIImage? {
        return self.scaledToFit(boundingSize: boundingSize)
    }
    
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size
    /// - Parameter boundingSize: size to fit the image into
    func scaledToFit(boundingSize: CGSize) -> UIImage? {
        var scale : CGFloat = boundingSize.width  / self.size.width
        scale = min(scale, boundingSize.height  / self.size.height)
        
        if scale != 1.0 {
            if let img = self.scaledByAxis(xscale: scale, yscale: scale) {
                return img
            }
        }
        return self
        
    }
    
    /// Returns a resized image, which will be the larged aspect-fit image into the given size (aspect fit to size that is both width and height of the given boundingSize)
    /// - Parameter size: size to fit the image into
    func scaledToFit(boundingSizes: CGFloat) -> UIImage? {
        return self.scaledToFit(boundingSize: CGSize(width: boundingSizes, height: boundingSizes))
    }
    
    /// Returns an image resized to the given scale, keeping aspect ratio
    /// scale is clamped betweeen > 0.0001 and < 1000.0, where 1.0 is the original scale, scale < 1.0 makes the image smaller than the original, and scale > 1.0 makes it bigger than original
    ///
    /// - Parameter scale: scale
    /// - Returns: an image scaled to the given multiplier, keeping the original's aspect ratio
    func scaled(_ scale:CGFloat = 1.0)->UIImage? {
        guard scale != 1.0 else {
            return self
        }
        let clampedScale = min(max(scale, 0.0001), 1000.0) // clamp(value: scale, lowerlimit: 0.0001, upperlimit: 1000.0)
        let newWidth = self.size.width * clampedScale
        let newHeight = self.size.height * clampedScale
        UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
        self.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    /// Returns an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    /// both scale parameters are clamped betweeen > 0.0001 and < 1000.0, where 1.0 is the original scale, scale < 1.0 makes the image smaller than the original on that axis, and scale > 1.0 makes it bigger than original on that axis
    ///
    /// - Parameters:
    ///   - xscale: scale to multiply the width
    ///   - yscale: scale to multiply the height
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func scaledByAxis(xscale:CGFloat = 1.0, yscale:CGFloat = 1.0)->UIImage? {
        guard xscale != 1.0 || yscale != 1.0 else {
            return self
        }
        let clampedX = clamp(value:xscale, lowerlimit: 0.0001, upperlimit: 1000.0)
        let clampedY = clamp(value:yscale, lowerlimit: 0.0001, upperlimit: 1000.0)
        let newWidth = self.size.width * clampedX
        let newHeight = self.size.height * clampedY
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
        self.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    /// Returns an image cropped using the given insets, having the original image NOT change size or scale and drawn inside the new image
    /// both inset parameters may be negative or positive, and indicate the insets with which the image size will be changed in each direction. That is, xInset will be subtracted on the left AND right side, and yInset will be subtracted on the top and bottom. The total size (width/height) change is twice the inset size's negative. Positive insets will crop (make image smaller), and negative insets will pad the image with transparent padding.
    /// both inset parameters are clamped betweeen > -1000.0 and < 1000.0. An image will not be cropped to a size smaller than 1 pixel in both aspects. In such cases, nil will be returned.
    ///
    /// - Parameters:
    ///   - xInset: inset by which to crop the image's height (negative value will pad the image with transparent bkg, enlarging its height)
    ///   - yInset: inset by which to crop the image's width (negative value will pad the image with transparent bkg, enlarging its wisth)
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func croppedByInsets(xInset:CGFloat = 0.0, yInset:CGFloat = 1.0, xoffset:CGFloat = 0.0, yoffset:CGFloat = 0.0)->UIImage? {
        if xInset == 0 && yInset == 0 {
            return self
        }
        
        let clampedX = clamp(value:xInset, lowerlimit: -1000.0, upperlimit: 1000.0)
        let clampedY = clamp(value:yInset, lowerlimit: -1000.0, upperlimit: 1000.0)
        let newWidth = max(self.size.width - (2*clampedX), 0)
        let newHeight = max(self.size.height - (2*clampedY), 0)
        
        if newWidth >= 1.0 && newHeight >= 1.0 {
            UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
            self.draw(in: CGRect(x:xInset + xoffset, y:yInset + yoffset, width:self.size.width, height:self.size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        return nil
    }
    
    
    
    /// Returns a segment of the original image cropped to a given rect
    /// - Parameter area: rectangle of the area to be cropped (this area will be returned)
    func cropped(area: CGRect) -> UIImage? {
        var rect = area
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    /// Returns an image padded / enlareged w/ transparent padding to the given insets, having the original image NOT change size or scale inside the new image
    /// both padding parameters may be negative or positive, and indicate the padding with which the image size will be changed in each direction. That is, xPadding will be added on the left AND right side, and yPadding will be added on the top and bottom. The total size (width/height) change is twice the inset size. Positive paddings  will pad the image with transparent padding. Negative paddings will crop (make image smaller).
    /// both padding parameters are clamped betweeen > -1000.0 and < 1000.0. An image will not be padded using negative values to a size smaller than 1 pixel in both aspects. In such cases, nil will be returned.
    ///
    /// - Parameters:
    ///   - xPadding: padding by which to pad the image's height (negative value will crop the image's width)
    ///   - yPadding: padding by which to pad the image's width (negative value will crop the image's width)
    /// - Returns: an image resized to the given scales, NOT neccesarily keeping the original aspect ratio
    func paddedWithPaddings(xPadding:CGFloat = 0.0, yPadding:CGFloat = 1.0, xoffset:CGFloat = 0.0, yoffset:CGFloat = 0.0)->UIImage? {
        return self.croppedByInsets(xInset:-xPadding, yInset:-yPadding, xoffset:xoffset, yoffset:yoffset)
    }
    
    func paddedWithPaddingEdges(top:CGFloat = 0.0, left:CGFloat = 1.0, bottom:CGFloat = 0.0, right:CGFloat = 0.0)->UIImage? {
        
        let newWidth = max(self.size.width + (left + right), 0)
        let newHeight = max(self.size.height + (top + bottom), 0)
        
        if newWidth >= 1.0 && newHeight >= 1.0 {
            UIGraphicsBeginImageContextWithOptions(CGSize(width:newWidth, height:newHeight), /*opaque:*/false, /*scale:*/self.scale)
            self.draw(in: CGRect(x:left, y:top, width:self.size.width, height:self.size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        return nil
    }
    
    /// Create solid colored image with a given size
    ///
    /// - Parameters:
    ///   - color: color for the image
    ///   - size: size for the image
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    /// Returns a gaussian blurred copy for a given image, with the same scale and sizes
    ///
    /// - Parameter redius: redius of blur
    /// - Returns: a tinted UIImage replication for self, or nil if failed
    func blurred(blurRadius:UInt)->UIImage? {

        let ciImage = CIImage(cgImage: self.cgImage!)
//        guard let ciImage = CIImage(cgImage: self.cgImage) else {
//            return nil
//        }
        
        let filter = CIFilter(_name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: "inputImage")
        filter?.setValue(blurRadius, forKey: "inputRadius")
        guard let output = filter?.outputImage else {
            return nil
        }
        let ciContext = CIContext(options: nil)
        var rect = CGRect(origin: CGPoint.zero, size: self.size)
        rect.size.width *= self.scale
        rect.size.height *= self.scale
        guard let cgImageRef = ciContext.createCGImage(output, from: rect) else {
            return nil
        }
        let result = UIImage(cgImage: cgImageRef)
        return result
    }
    
}

extension UIImage /* +URL */{
    
    // MARK:- Error handling
    /// contains a LocalizedError for when the load image extentions fail.
    public struct LoadImageError: LocalizedError {
        private let message:String
        public init(_ message:String) {
            self.message = message
        }
        public var errorDescription: String? { get { return self.message } }
        public var failureReason: String? { get { return self.message } }
        public var recoverySuggestion: String? { get { return self.message } }
        public var helpAnchor: String? { get { return self.message } }
    }
    
    public static func loadImage( fromURL:URL, completionHandler: @escaping (_ image:UIImage?, _ error:LocalizedError?)->Void) {
        if fromURL.isFileURL {
            do {
                let data = try Data(contentsOf: fromURL)
                let result = UIImage(data: data, scale: UIScreen.main.scale)
                completionHandler(result, nil)
            } catch let error as NSError {
                completionHandler(nil, LoadImageError("unable to convert data in url \(fromURL.path) to image. error:\(error.description)"))
            }
        } else {
            URLSession(configuration: .default)
                .dataTask(with: fromURL) { (data, response, error) in
                    if let error = error {
                        completionHandler(nil, LoadImageError(error.localizedDescription))
                        return
                    }
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode != 200 {
                            completionHandler(nil, LoadImageError("bad response \(response.statusCode) - \(response.description)"))
                            return
                        }
                        if let data = data {
                            if let image = UIImage(data: data) {
                                completionHandler(image, nil)
                                return
                            }
                            if response.mimeType?.contains("text") ?? false ||
                                response.mimeType?.contains("json") ?? false {
                                completionHandler(nil, LoadImageError("unable to convert data " + (String(data: data, encoding: .utf8) ?? "\(data)") + " to image"))
                                return
                            }
                            completionHandler(nil, LoadImageError("unable to convert data \(data) to image"))
                            return
                        }
                        completionHandler(nil, LoadImageError("unable to retrieve response data"))
                        return
                    }
                    completionHandler(nil, LoadImageError("unknown response type"))
                }.resume()
        }
    }
}
#endif
