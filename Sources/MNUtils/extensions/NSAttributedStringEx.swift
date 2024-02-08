//
//  NSAttributedStringEx.swift
// Created by Ido Rabin for Bricks on 17/1/2024.
//  Copyright © 2022 . All rights reserved.
//

import Foundation
import AppKit
import Logging

fileprivate let dlog : Logger? = Logger(label: "AttributedStringEx")


public class AttributedString : Codable, Equatable, Hashable {
    
    let attributedString : NSAttributedString
    
    init(nsAttributedString : NSAttributedString) {
        self.attributedString = nsAttributedString
    }
    
    // MARK: Decodable
    public required init(from decoder: Decoder) throws {
        let singleContainer = try decoder.singleValueContainer()
        let base64String = try singleContainer.decode(String.self)
        guard let data = Data(base64Encoded: base64String) else { throw DecodingError.dataCorruptedError(in: singleContainer, debugDescription: "String is not a base64 encoded string") }
        guard let attributedString = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSAttributedString.self], from: data) as? NSAttributedString else { throw DecodingError.dataCorruptedError(in: singleContainer, debugDescription: "Data is not NSAttributedString") }
        self.attributedString = attributedString
    }
    
    // MARK: Encodable
    public func encode(to encoder: Encoder) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: false)
        var singleContainer = encoder.singleValueContainer()
        try singleContainer.encode(data.base64EncodedString())
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(attributedString)
    }
    
    // MARK: Equatable
    public static func == (lhs: AttributedString, rhs: AttributedString) -> Bool {
        return lhs.attributedString == rhs.attributedString
    }
}

public enum AttributedStringMatchFilter {
    case all
    case first
    case last
}

public extension String {
    
    /// Find all ranges where a given substring exists within a string
    ///
    /// - Parameter substring: substring to find
    /// - Returns: array of substrings and their corresponding NSRanges within the string
    func findAllStringRangeMatches(substring:String, isCaseSensitive:Bool = true, isStopAtFirstResult : Bool = false)->[(string:String, range:NSRange)] {
        if substring.count > 0 {
            
            // Optimization if equals
            if substring.hashValue == self.hashValue && substring == self {
                return [(string:substring, range:NSRange(location: 0, length: substring.count))]
            }
            
            if isStopAtFirstResult {
                if let rng = self.range(of: substring, options: isCaseSensitive ? String.CompareOptions.caseInsensitive : [], range: nil, locale: nil) {
                    return [(string:substring, range:self.nsRange(from: rng)!)] //
                }
            }
            
            do {
                let strRegEx = NSRegularExpression.escapedPattern(for: substring)
                let regex = try NSRegularExpression(pattern: strRegEx, options:isCaseSensitive ? [] : [NSRegularExpression.Options.caseInsensitive])
                let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
                let result = results.map {
                    (string:String(self[Range($0.range, in: self)!]), range:$0.range)
                }
                return result
            } catch let error {
                dlog?.warning("invalid regex: \(error.localizedDescription)")
                return []
            }
        } else {
            dlog?.warning("findAllStringRangeMatches:substring regex length was 0: \(substring)")
        }
        
        return []
    }
    
    
    /// Return all ranges where the string contains a substring that has a given prefix and ends with a given suffix
    ///
    /// - Parameters:
    ///   - startingWith: prefix for the substring
    ///   - endingWith: suffix for the substring
    /// - Returns: array of substrings and their corresponding NSRanges within the string
    func findAllStringRangeMatches(startingWith:String, endingWith:String, isCaseSensitive:Bool = true)->[(string:String, range:NSRange)] {
        if (startingWith.count > 0 && endingWith.count > 0) {
            do {
                let startRegEx = NSRegularExpression.escapedPattern(for: startingWith)
                let endRegEx = NSRegularExpression.escapedPattern(for: endingWith)
                let regexStr = "\(startRegEx)(?:(?!\(startRegEx)).)*?\(endRegEx)"
                let regex = try NSRegularExpression(pattern: regexStr, options: isCaseSensitive ? [] : [NSRegularExpression.Options.caseInsensitive])
                let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
                let result = results.map {
                    (string:String(self[Range($0.range, in: self)!]), range:$0.range)
                }
                return result
            } catch let error {
                dlog?.warning("invalid regex: \(error.localizedDescription)")
                return []
            }
        } else {
            dlog?.warning("findAllStringRangeMatches:startingWith: regex length was 0: startingWith:\(startingWith) endingWith:\(endingWith)")
        }
        return []
    }
    
    
    
    /// Returns a string that will fit to it's container's measures with a suffix (i.e. "read more")
    ///
    /// - Parameters:
    ///   - suffixStr: A suffix string to add to this string
    ///   - boundingSize: The string's container's size
    ///   - attributes: NSAttributingString attributes. Must have 'font' in so the func can calc the string's size)
    /// - Returns: Resized string combined with suffix
    func getBestFittingString(suffix suffixStr:String, boundingSize: CGSize, attributes: [NSAttributedString.Key : Any]) -> String {
        let array = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        var accumulatedStr = ""
        var accumulatedStrPrevious = ""
        let requiredHeight: CGFloat = boundingSize.height
        for word in array {
            // Accumulate a string
            accumulatedStr += word  + " " //add the space we removed when splitting the str
            
            // Test if it fits in our frame:
            let spacer = String.NBSP
            // We get the size of the accum string with the attrbutes
            let size = NSString(string:accumulatedStr + "...\(spacer)" + suffixStr).boundingRect(with: CGSize(width: boundingSize.width, height: requiredHeight + 1000.0), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            if  size.height < requiredHeight {
                accumulatedStrPrevious = accumulatedStr + "...\(spacer)" + suffixStr
            } else {
                break
            }
        }
        return accumulatedStrPrevious
    }
    
    
    /// Check if the whoe string fits inside a given bounding size
    /// - Parameters:
    ///   - sze: size to fit the strinbg into
    ///   - attributes: attributes to use
    /// - Returns: true if the whole text (untrimmed, cliiped or changed) will fit into the provided size
    func willFitBoundingSize(_ sze:CGSize, attributes: [NSAttributedString.Key : Any])->Bool {
        let rect = (self as NSString).boundingRect(with: sze.changed(height: 9000), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        // return true when the text bounding rect fits into the size
        return rect.width <= sze.width && rect.height <= sze.height
    }
    
    @available(macOS 10.15, iOS 14.0, *)
    func getBestFittingFont(forBoundingSize size: CGSize, baseFont:NSFont, forceInitialSize:CGFloat? = nil) -> NSFont {
        var isFit = false
        func roundz(_ sze:CGFloat)->CGFloat {
            return round(sze * 10.0) / 10.0
        }
        var pointSze : CGFloat = forceInitialSize ?? 16.0
        var prevSze : CGFloat = 0.0
        var jumpSze : CGFloat = pointSze * 0.5
        var font = baseFont
        var iterations : Int = 0
        //DLog.ui.info("best fit font: [\(baseFont.fontName)] init pointSze: [\(pointSze)] into size:\(size)")
        while isFit == false && iterations < 20 && abs(prevSze - pointSze) > 0.5 {
            font = font.withSize(round(pointSze * 100)/100)
            prevSze = pointSze
            // DLog.ui.info("  best fit pointSze: \(String(format:"%0.2f", pointSze))")
            let rect = (self as NSString).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [.font:font], context: nil).rounded()
            if rect.height > size.height || rect.width > size.width {
                isFit = false
                if pointSze > 1 {
                    // font is too big:
                    pointSze -= jumpSze
                    if jumpSze > 0.5 {
                        jumpSze *= 0.75
                    }
                }
            } else if rect.height < size.height || rect.width < size.width {
                isFit = rect.height > size.height - 1 && rect.width > size.width - 1
                if !isFit && pointSze > 1 {
                    // font is too big:
                    pointSze += jumpSze
                    if jumpSze > 0.5 {
                        jumpSze *= 0.75
                    }
                }
            } else {
                isFit = true
            }
            
            iterations += 1
        }
        
        // Clamp point size
        pointSze = clamp(value: pointSze, lowerlimit: 6, upperlimit: 72 )
        font = baseFont.withSize(pointSze)
        
        return isFit || abs(pointSze - prevSze) < 1.5 ? font : baseFont
    }
    
    func boundingRect(with size: NSSize, options: NSString.DrawingOptions =  [], attributes: [NSAttributedString.Key : Any]? = nil, context: NSStringDrawingContext?)->CGRect {
        return (self as NSString).boundingRect(with: size, options: options, attributes: attributes, context: context)
    }
}

public extension NSMutableAttributedString {
    
    
    /// Set attributes for all sub strings matching the given match string. mutates the original string.
    ///
    /// - Parameters:
    ///   - matches: string to search substrings
    ///   - within: substring matches may be limited onlt to the ranges of this substring
    ///   - attributes: attributes to apple
    /// - Returns: number of matches found and changed
    @discardableResult
    func setAtttibutesForStrings(matching match:String, within : String? = nil, filter:AttributedStringMatchFilter = .all, isCaseSensitive:Bool = true, attributes:[NSAttributedString.Key : Any])->Int {
        guard string.count > 0 else {
            return 0
        }
        
        return self.setAtttibutesForStrings(matching: [match], within:within, filter:filter, isCaseSensitive:isCaseSensitive, attributes: attributes)
    }
    
    /// Set attributes for all sub strings matching the given match strings. mutates the original string.
    ///
    /// - Parameters:
    ///   - matches: strings to search substrings
    ///   - within:  substring matches may be limited onlt to the ranges of this substring
    ///   - attributes: attributes to apple
    /// - Returns: number of matches found and changed
    @discardableResult
    func setAtttibutesForStrings(matching matches:[String], within:String? = nil, filter:AttributedStringMatchFilter = .all, isCaseSensitive:Bool = true, attributes:[NSAttributedString.Key : Any])->Int {
        var rangesItems : [(string:String, range:NSRange)] = []
        var withinRanges : [(string:String, range:NSRange)] = []
        if let within = within {
            withinRanges = self.string.findAllStringRangeMatches(substring: within, isCaseSensitive:isCaseSensitive)
        }
        
        for match in matches {
            if match.count > 0 {
                let foundItems = self.string.findAllStringRangeMatches(substring: match, isCaseSensitive:isCaseSensitive, isStopAtFirstResult:(filter == .first))
                
                if withinRanges.count > 0 {
                    for item in foundItems {
                        for withinItem in withinRanges {
                            if item.range.intersection(withinItem.range) != nil {
                                rangesItems.append(item)
                                break
                            }
                        }
                        
                        if filter == .first && rangesItems.count > 0 {
                            break // Optimization
                        }
                    }
                    
                } else {
                    rangesItems.append(contentsOf: foundItems)
                    
                    if filter == .first {
                        break // Optimization
                    }
                }
            }
        }
        
        switch filter {
        case .first:
            rangesItems = rangesItems.count > 0 ? [rangesItems.first!] : []
        case .last:
            rangesItems = rangesItems.count > 0 ?  [rangesItems.last!] : []
        case .all:
            // does nothing
            break
        }
        
        for rangeItem in rangesItems {
            self.setAttributes(attributes, range: rangeItem.range)
        }
        
        return rangesItems.count
    }
    
    /// Set attributes for all substrings of the attributed string starting with a given prefix and ending with a given suffix. mutates the original string.
    ///
    /// - Parameters:
    ///   - startingWith: prefix for substrings to be changed
    ///   - endingWith: suffic for substrings to be changed
    ///   - attributes: NSAttributedStringKey:value paris to apply for the found substrings
    ///   - replacingWithEmpty: when true, will replace the prefix and suffix searched parts with an empty string, when false, will keep string in original forms
    /// - Returns: either 0 or when replacingWithEmpty is true, the sum of cahrachters deleted from the string
    @discardableResult
    func setAtttibutesForStrings(startingWith:String, endingWith:String, filter:AttributedStringMatchFilter = .all, isCaseSensitive:Bool = true, attributes:[NSAttributedString.Key : Any], replacingWithEmpty:Bool = true)->Int {
        var ranges = self.string.findAllStringRangeMatches(startingWith: startingWith, endingWith: endingWith, isCaseSensitive:isCaseSensitive)
        
        switch filter {
        case .first:
            ranges = ranges.count > 0 ? [ranges.first!] : []
        case .last:
            ranges = ranges.count > 0 ?  [ranges.last!] : []
        case .all:
            // does nothing
            break
        }
        
        for rangeItem in ranges {
            self.setAttributes(attributes, range: rangeItem.range)
        }
        
        var sumDeleted = 0
        for rangeItem in ranges {
            if replacingWithEmpty {
                self.deleteCharacters(in: NSMakeRange(rangeItem.range.location - sumDeleted, startingWith.count))
                sumDeleted += startingWith.count
                self.deleteCharacters(in: NSMakeRange(rangeItem.range.location + rangeItem.range.length - sumDeleted - endingWith.count, endingWith.count))
                sumDeleted += endingWith.count
            }
        }
        
        return ranges.count
    }
    
    /// Set attributes for all substrings of the attributed string starting and ending with a given prefix/suffix
    /// Examples: in "Moshe is a very *nice* boy", using "*" as the startingAndEndingWith, and adding a bold font attribute will result in the word "*nice*" being bold. If setting replacingWithEmpty to true the result will mutate to "Moshe is a very nice boy", where "nice" will be bold
    ///
    ///
    /// - Parameters:
    ///   - startingAndEndingWith: prefix and suffi for substrings to be changed. The substrings are expected to have the same string as a prefix and suffix
    ///   - attributes: NSAttributedStringKey:value paris to apply for the found substrings
    ///   - replacingWithEmpty: when true, will replace the prefix and suffix searched parts with an empty string, when false, will keep string in original forms
    /// - Returns: either 0 or when replacingWithEmpty is true, the sum of cahrachters deleted from the string
    @discardableResult
    func setAtttibutesForStrings(startingAndEndingWith:String, attributes:[NSAttributedString.Key : Any], replacingWithEmpty:Bool = true)->Int {
        return self.setAtttibutesForStrings(startingWith: startingAndEndingWith, endingWith: startingAndEndingWith, attributes:attributes)
    }
    
    /// Set attributes for all sub strings matching the given match strings. mutates the original string.
    ///
    /// - Parameters:
    ///   - matches: strings to search substrings
    ///   - within:  substring matches may be limited onlt to the ranges of this substring
    ///   - attributes: attributes to apple
    /// - Returns: number of matches found and changed
    @discardableResult
    func setAtttibutesForAllStrings(matching matches:[String], within:String? = nil, isCaseSensitive:Bool = true, attributes:[NSAttributedString.Key : Any])->Int {
        var rangesItems : [(string:String, range:NSRange)] = []
        var withinRanges : [(string:String, range:NSRange)] = []
        if let within = within {
            withinRanges = self.string.findAllStringRangeMatches(substring: within, isCaseSensitive:isCaseSensitive)
        }
        
        for match in matches {
            let foundItems = self.string.findAllStringRangeMatches(substring: match, isCaseSensitive:isCaseSensitive)
            
            if withinRanges.count > 0 {
                for item in foundItems {
                    for withinItem in withinRanges {
                        if item.range.intersection(withinItem.range) != nil {
                            rangesItems.append(item)
                            break
                        }
                    }
                }
                
            } else {
                rangesItems.append(contentsOf: foundItems)
            }
            
        }
        
        for rangeItem in rangesItems {
            self.setAttributes(attributes, range: rangeItem.range) // convertToOptionalNSAttributedStringKeyDictionary(attributes)
        }
        
        return rangesItems.count
    }
}
