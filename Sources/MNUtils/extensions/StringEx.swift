//
//  StringEx.swift
//
//
//  Created by Ido Rabin on 17/05/2023.
//  Copyright © 2022 . All rights reserved.
//

import Cocoa

public extension Sequence where Iterator.Element == String {
    func lowercased(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.lowercased(with: locale)
        }
    }
    
    func uppercased(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.uppercased(with: locale)
        }
    }
    func capitalized(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.capitalized(with: locale)
        }
    }
}

public extension String {

    /// Return a substring from index (as int)
    /// - Parameters:
    ///   - from: index int location of first charahter to return a substring from
    ///   - suffixIfClipped: if the resulting string is shorter than the original string, will append this string as suffix (Default is nil, in which case nothing is appended to the string...).
    /// - Returns: a substring of the given sring from the given index and until the end of the string
    func substring(from: Int, suffixIfClipped:String? = nil) -> String {
        if from <= 0 {
            return self
        }

        let start = index(startIndex, offsetBy: from)
        var result = String(self[start ..< endIndex])
        if result.count < self.count, let suffixIfClipped = suffixIfClipped {
            result += suffixIfClipped
        }
        return result
    }
    
    /// Return a substring until index (as int)
    /// - Parameters:
    ///   - to: index int location of last charahter to return a substring until (not included)
    ///   - suffixIfClipped: if the resulting string is shorter than the original string, will append this string as suffix (Default is nil, in which case nothing is appended to the string...).
    /// - Returns: a substring of the given sring from the cahr at index 0 until the given index (not included)
    func substring(to: Int, suffixIfClipped:String? = nil) -> String {
        let end = index(startIndex, offsetBy: Swift.min(to, endIndex.utf16Offset(in: self)))
        var result = String(self[startIndex ..< end])
        if result.count < self.count, let suffixIfClipped = suffixIfClipped {
            result += suffixIfClipped
        }
        return result
    }
    
    func substring(maxSize: Int, midIfClipped:String? = nil) -> String {
        guard self.count > maxSize else { return self }
        let midStr = midIfClipped ?? ""
        let headCharactersCount = Int(ceil(Float(maxSize - midStr.count) / 2.0))
        
        let tailCharactersCount = Int(floor(Float(maxSize - midStr.count) / 2.0))
        return "\(self.prefix(headCharactersCount))\(midStr)\(self.suffix(tailCharactersCount))"
    }

    /// Returns a new string where the charahters at indexes of the given rage were replaced.
    ///
    /// - Parameters:
    ///   - range: Int Range (CountableClosedRange)
    ///   - replacementString: string to insert instead of the given range of charahters
    /// - Returns: resulting manipulated string
    func replacing(range: CountableClosedRange<Int>, with replacementString: String) -> String {
        let rng = NSRange(location: range.lowerBound, length: max(range.upperBound - range.lowerBound, 1))
        if let range = self.range(from: rng) {
            return self.replacingCharacters(in: range, with: replacementString)
        }
        preconditionFailure("String replacing(range: CountableClosedRange<Int> range out of bounds!")
    }
    
    func replacing(range: CountableRange<Int>, with replacementString: String) -> String {
        let rng = NSRange(location: range.lowerBound, length: max(range.upperBound - range.lowerBound, 1))
        if let range = self.range(from: rng) {
            return self.replacingCharacters(in: range, with: replacementString)
        }
        preconditionFailure("String replacing(range: CountableRange<Int> range out of bounds!")
    }
    
    /// Replace occurance of any char from the given char set to a uniform, single string
    ///
    /// - Parameters:
    ///   - set: charahter set to replace
    ///   - with: string to replace the charahters with
    /// - Returns: a string where each charahter of the given set is replaed with the given string
    func replacingOccurrences(of set:CharacterSet, with:String) -> String {
        return self.components(separatedBy: set)
            .filter { !$0.isEmpty }
            .joined(separator: with)
    }
    
    func replacingOccurrences(of set:CharacterSet, withRandomCharsOutOf charsRange:String) -> String {
        var result : String = ""
        for i in 0..<self.count {
            if let char = self.substring(atIndex: i) {
                if char.trimmingCharacters(in: set).count == 0 {
                    let index = Int(arc4random() % UInt32(charsRange.count))
                    let randomChar = charsRange.substring(atIndex: index) ?? " "
                    result.append(randomChar)
                } else {
                    result.append(char)
                }
            }
        }
        return result
    }
    
    
    ///
    ///
    /// - Parameter keyValues: keys to be replaced by their values
    /// - Returns: a new string where all occurences of given keys are replaced with their corresponding values
    ///
    
    
    
    /// /// Replaces all occurences of given keys with their corresponding values
    /// Example: for the string "hello simon and good day. hello!" and the given dictionary ["hello":"goodbye", "good":"have a great"],
    /// The resulting string would be "goodbye simon and have a great day. googbye!"
    /// - Parameters:
    ///   - keyValues: keys to be replaced by their values
    ///   - caseSensitive: should replace occurances with regard of case, otherwise will be replace any occurance of any case (case insensitive replacement)
    /// - Returns: a new string where all occurences of given keys are replaced with their corresponding values
    func replacingOccurrences(ofFromTo keyValues:[String:String], caseSensitive:Bool = true) -> String {
        var str = self
        for (key, value) in keyValues {
            str = str.replacingOccurrences(of: key, with: value, options: caseSensitive ? [] : [.caseInsensitive])
        }
        return str
    }
    
    /// Validate if the string is a valid email address (uses a simple regex)
    ///
    /// - Returns: true when email is valid
    func isValidEmail()->Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    /// Returns the domain of the email IF the string is a valid email address
    ///
    /// - Returns: email address domain or nil
    func emailDomain()->String?
    {
        if self.isValidEmail() {
            let components = self.components(separatedBy: "@").last?.components(separatedBy: ".")
            if let components = components {
                let sindex = components.endIndex.advanced(by: -2)
                return components[sindex]
            }
        }
        
        return nil
    }
    
    
    /// Will return a "fixed" url string if the string was close enough to a valid url
    func isValidPossibleURL()->String? {
        var vals = [self]
        if !self.hasPrefix("https://") {
            vals.append("https://\(self)")
        }
        if !self.hasPrefix("http://") {
            vals.append("http://\(self)")
        }
        for val in vals {
            if URL(string:val) != nil {
                return val
            }
        }
        
        return nil
    }
    
    
    /// Returns true is the string can be split into two valid names: first name and last name components
    /// Conditions are that the string ahs at least 2 chars on either side of a whitespae charahter
    ///
    /// - Returns: true
    func isValidPossibleFullName()->Bool {
        if self.count < 4 {return false}
        
        let comps = self.components(separatedBy: CharacterSet.whitespaces)
        if comps.count < 2 {return false}
        var count = 0
        for comp in comps {
            if comp.count > 1 {
                count += 1
            }
        }
        if count < 2 {return false}
        
        return true
    }
    
    
    /// Returns the string split into two parts if they are valid parts of a full name
    ///
    /// - Returns: first name and last name tuple when the name is valid
    func componentsAsFullName()->(givenName:String, familyName:String)? {
        if !isValidPossibleFullName() {
            return nil
        }
        
        let comps = self.components(separatedBy: CharacterSet.whitespaces)
        if comps.count < 2 {return nil}
        if comps.count == 3 {
            return (givenName:comps.first! + " " + comps[1], familyName:comps.last!)
        }
        return (givenName:comps.first!, familyName:comps.last!)
    }
    
    
    static func validPasswordMinLength()->Int {
        return 8
    }
    
    /// Return if a candidate string is a valid password (in its plaintext form, i,e does the password conform to the minimum requirements from a plaintext pwd - complaxity wise)
    /// Currently the password MUST be comprised of at least 8 chars, 1 uppercase, one digit
    ///
    /// - Returns: true when teh string is a valid password
    func isPlaintextValidPassword()->Bool {
        
        // Examples: (pick and use)
        /*
         ^                         Start anchor
         (?=.*[A-Z].*[A-Z])        Ensure string has two uppercase letters.
         (?=.*[!@#$&*])            Ensure string has one special case letter.
         (?=.*[0-9].*[0-9])        Ensure string has two digits.
         (?=.*[a-z].*[a-z].*[a-z]) Ensure string has three lowercase letters.
         .{8}                      Ensure string is at least of length 8.
         $                         End anchor.
         */
        
        
        var isPassedAllTests = true
        // At least one uppercase, one digit, at least validPasswordMinLength chars length (up to 20)
        let regexes = ["^(?=.*\\d).{\(String.validPasswordMinLength()),}$", "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"]
        for regex in regexes {
            let passTest = NSPredicate(format:"SELF MATCHES %@", regex)
            isPassedAllTests = isPassedAllTests && passTest.evaluate(with: self)
        }
        
        // Actual test:
        
        return isPassedAllTests
    }
    
    
    /// Will return the last path compoment of the string IF it can be split into a url, otherwise, will return the whole string
    ///
    /// - Returns: Either the last path component or the original string as a whole
    func lastPathComponent()->String {
        if let url = URL(string:self) {
            return url.lastPathComponent
        }
        return self
    }
    
    /// Return the last X path components for a given url
    ///
    /// - Parameter count: amount of suffixing components to return, delimited by "/"
    /// - Returns: String of last components, by order of appearance in the URL, joined by "/"
    func lastPathComponents(count:Int)->String {
        if let url = URL(string:self) {
            return url.lastPathComponents(count: count)
        }
        return self
    }
    
    
    /// Pad the string from its left side only with a charahter to fill up to a given total length of the string. If the string is already that length or bigger, no change will take place
    ///
    /// - Parameters:
    ///   - toLength: the length up to which the string is to be padded from the left
    ///   - character: the pad element to repeat as the filler padding in the left side of the string.
    ///   - padIndex: the char index from the left to start padding at
    /// - Returns: a string padded from its left side with the given pad element
    func paddingLeft(toLength: Int, withPad character: Character) -> String {
        if toLength <= 0 {return self}
        
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
    
    /// Pad the string from its left side only with a charahter to add a given amount of the pad element.
    ///
    /// - Parameters:
    ///   - padCount: amout of times to repeat the pad element
    ///   - character: the charahter / element to repeat as the filler padding in the left side of the string.
    /// - Returns: a string padded from its left side with the given pad element
    func paddingLeft(padCount: Int, withPad character: Character) -> String {
        if padCount <= 0 {return self}
        
        // let stringLength = self.count
        return String(repeatElement(character, count: padCount)) + self
    }
    
    /// Pad the string from its righ side only with a charahter to add a given amount of the pad element.
    ///
    /// - Parameters:
    ///   - padCount: amout of times to repeat the pad element
    ///   - character: the charahter / element to repeat as the filler padding in the righ side of the string.
    /// - Returns: a string padded from its righ side with the given pad element
    func paddingRight(padCount: Int, withPad character: Character) -> String {
        if padCount <= 0 {return self}
        
        return self + String(repeatElement(character, count: padCount))
    }
    
    /// Will create a string trimming only from its left side any charahter from the given set. When encountering the first charahter that is not part of the set, the trimming will stop.
    /// Example: for the string ".!? simon, that is great!", using CharacterSet.punctuationCharacters will return
    /// "simon, this is great!"
    ///
    /// - Parameter set: a charahter set to use for the trimming
    /// - Returns: a string with its left side trimmed from all the the charahters in the set
    func trimmingPrefixCharacters(in set: CharacterSet) -> String {
        if self.count == 0 {return self}

        for index in 1..<self.count {
            let substr = self.substring(to: index)
            if substr.trimmingCharacters(in: set).count > 0 {
                return self.substring(from: index - 1)
            }
        }
        
        return self
    }
    
    /// Will create a string trimming only from its right side any charahter from the given set. When encountering the first charahter that is not part of the set, the trimming will stop.
    /// Example: for the string "simon, is this great!?", using CharacterSet.punctuationCharacters will return
    /// "simon, is this great"
    ///
    /// - Parameter set: a charahter set to use for the trimming
    /// - Returns: a string with its right side trimmed from all the the charahters in the set
    func trimmingSuffixCharacters(in set: CharacterSet) -> String {
        if self.count == 0 {return self}
        
        for index in 1..<self.count {
            let substr = self.substring(from: self.count - index)
            if substr.trimmingCharacters(in: set).count > 0 {
                return self.substring(to: self.count - index + 1)
            }
        }
        
        return self
    }
    
    
    /// Trim a prefix string only if the prefix string is indeed at the beginning of the string
    /// NOTE: will trim the first min(self.count / 256) cosecutive repetitions of prefix
    /// - Parameter prefix: expected prefix
    /// - Returns: a new string without the expected prefix, or, the original string if it does not contain the given string as a prefix
    func trimmingPrefix(_ prefix: String) -> String {
        var loopLimit = min(self.count, 256)
        var str = self
        while str.count > 1 && str.hasPrefix(prefix) && loopLimit >= 0 {
            str = str.substring(from: prefix.count)
            loopLimit -= 1
        }
        
        // JIC substring
        if str == prefix {
            return ""
        }
        
        return str
    }
    
    /// Trim a suffix string only if the suffix string is indeed at the end of the string
    /// NOTE: will trim the first min(self.count / 256) cosecutive repetitions of suffix
    /// - Parameter suffix: expected suffix
    /// - Returns: a new string without the expected suffix, or, the original string if it does not contain the given string as a suffix
    func trimmingSuffix(_ suffix: String) -> String {
        var loopLimit = min(self.count, 256) // safe(r) loop limit
        var str = self
        while str.count > 1 && str.hasSuffix(suffix) && loopLimit >= 0 {
            str = str.substring(to: max(self.count - suffix.count - 1, 1))
            loopLimit -= 1
        }
        
        if str == suffix {
            return ""
        }
        return str
    }
    
    
    /// Returns true when the string contains ANY charahter in the given charahter set
    /// NOTE: not efficient, do not use with big strings
    /// - Parameter set:set of charahters to be found in the string
    /// - Returns:true when the string contains at least one charahter in the set.
    func contains(anyIn set:CharacterSet)->Bool {
        return self.replacingOccurrences(of: set, with: "").count < self.count
    }
    
    
    /// Returns true when the string is composed SOLELY of charachters from the given characcter set and no other chars.
    /// - Parameter set: set to test against
    /// - Returns: true if all chars belong to the given char set
    func containedByCharSet(_ set:CharacterSet)->Bool {
        return self.replacingOccurrences(of: set, with: "").count == 0
    }
    
    func contains(_ item:String, isCaseSensitive:Bool)->Bool {
        if let range = self.range(of: item, options: (isCaseSensitive ? [] : [.caseInsensitive])) {
            return !range.isEmpty && range.upperBound <= self.endIndex
        } else {
            return false
        }
    }
    
    
    /// Returns true is this string contains any of the strings in the given array
    /// // Note: test order is according to array order, and will stop testing after first found item
    /// - Parameter items:items to look for in the string.
    func contains(anyOf items:[String], isCaseSensitive:Bool = true)->Bool {
        for item in items {
            if self.contains(item, isCaseSensitive:isCaseSensitive) {
                return true
            }
        }
        return false
    }
    
    /// Returns true when the string contains all of the given items as substrings - note - does not account for overlaps.
    /// - Parameters:
    ///   - items: items: substrigs to find
    ///   - isCaseSensitive: determines if the search should be case sensitive or not
    /// - Returns: true if contains all of the given substrings
    func contains(allOf items:[String], isCaseSensitive:Bool = true)->Bool {
        for item in items {
            if !self.contains(item, isCaseSensitive: isCaseSensitive) {
                return false // on of the substrings is missing
            }
        }
        return true // contains all
    }
    
    
    /// Returns true when the string contains at least one of each of the given items as substrings - note - does not account for overlaps.
    /// - Parameters:
    ///   - items: substrigs to find
    ///   - isCaseSensitive: determines if the search should be case sensitive or not
    /// - Returns: true if contains at least one of each of the given substrings is contained by the string
    func contains(atLeastOneOfEach items:[String], isCaseSensitive:Bool = true)->Bool {
        var remaining = items.uniqueElements() // will be shrinking until empty
        var loopLimit = (remaining.count * remaining.count) + 1
        while remaining.count > 0 && loopLimit > 0 {
            for item in remaining {
                if let _ = self.range(of: item, options: isCaseSensitive ? [] : [.caseInsensitive]) {
                    remaining.remove(elementsEqualTo: item)
                    break;
                }
            }
            loopLimit -= 1
        }
        
        return remaining.count == 0 //
    }
    
    /// Returns true when the string ENDS with the wanted expression
    /// adds to the regex a "$" at the end
    func hasSuffixMatching(_ regex:String, options:NSRegularExpression.Options = [])->Bool {
        let substr = self.substring(from: max(self.count - regex.count, 0))
        let complete = regex.hasSuffix("$") ? regex : (regex + "$")
        return substr.matchRanges(for: complete, options: options).count > 0
    }
    
    /// Returns true when the string STARTS with the wanted expression
    /// adds to the regex a "^" at the start
    func hasPrefixMatching(_ regex:String, options:NSRegularExpression.Options = [])->Bool {
        let substr = self // - all string
        let complete = regex.hasPrefix("^") ? regex : ("^" + regex)
        return substr.matchRanges(for: complete, options: options).count > 0
    }
    
    /// Will return a suffix with the given length or smaller, or an empty string
    /// - Parameter size: maximun length of suffix required
    func safeSuffix(maxSize: Int, suffixIfClipped:String? = nil) -> String {
        return substring(from: self.count - maxSize, suffixIfClipped:suffixIfClipped)
    }
    
    /// Will return a prefix with the given length or smaller, or an empty string
    /// - Parameter size: maximun length of prefix required
    func safePrefix(maxSize: Int, suffixIfClipped:String? = nil) -> String {
        return substring(to: maxSize, suffixIfClipped:suffixIfClipped)
    }

    
    /// Return a string that is the original string repeated times amount.
    /// for "N".repeated(times:3) we get "NNN"
    /// - Parameter times: times to repeat
    /// - Returns the original string repeated times. If times smaller than 1, we get an empty string.
    func repeated(times:Int)->String {
        guard times > 0 else {
            return ""
        }
        return String(repeating: self, count: times)
    }
    
    func repeated(times:UInt)->String {
        return self.repeated(times: Int(times))
    }
}

public extension StaticString {
    
    /// Will return the last path compoment of the string IF it can be split into a url, otherwise, will return the whole string
    ///
    /// - Returns: Either the last path component or the original string as a whole
    func lastPathComponent()->String {
        return self.description.lastPathComponent()
    }
}

// NSRange / Range<String.Index> conversions

public extension String {
    
    
    /// Returns an NSRange describing the whole length of the string (from start index to the last index)
    ///
    /// - Returns: NSRange for the whole string
    func nsRangeForWholeString() -> NSRange? {
        if let from = self.startIndex.samePosition(in: utf16) {
            if let to = self.endIndex.samePosition(in: utf16) {
                return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                               length: utf16.distance(from: from, to: to))
            }
        }
        
        return nil
    }
    
    
    /// Convert Range<String.Index> to NSRange
    ///
    /// - Parameter range: range in new swift <String.Index> type
    /// - Returns: NSRange in int, assuming .utf16 encoding
    func nsRange(from range: Range<String.Index>) -> NSRange? {
        if let from = range.lowerBound.samePosition(in: utf16) {
            if let to = range.upperBound.samePosition(in: utf16) {
                return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                               length: utf16.distance(from: from, to: to))
            }
        }
        
        return nil
    }

    /// Convert NSRange to new swift Range<String.Index>
    ///
    /// - Parameter range: NSrange to convert from
    /// - Returns: Range<String.Index>? assuming .utf16 encoding
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    
    /// Given a string with digits, will attempt to search for the first found range of the same consecutive digit sequence in the given string, ignoring other charahters
    /// Example: "+1(234) 563456".rangeOfDigits("3456") will return the range of (3,4) and the "34) 56" substring
    /// NOTE: Search is limited to max length of 100 either or the digits string or self string
    ///
    /// - Parameter digits: digit sequence to search for
    /// - Returns: range of the digit sequence in the string, including delimiting charahters which are not digits and the found substring, including the other charahters
    func rangesOfDigits(digits:String) -> [(range:Range<String.Index>,substring:String)]? {
        
        var results : [(range:Range<String.Index>,substring:String)]? = []
        
        let digitsStr : String = digits.replacingOccurrences(of: CharacterSet.decimalDigits.inverted, with: "")
        if digitsStr.count > 0 && digitsStr.count < 100 && self.count < 100 {
            do {
                let digits : [String] = digitsStr.map { String($0) }
                let regexPattern = "(" + digits.joined(separator: "\\D{0,2}") + ")"
                let regex = try NSRegularExpression(pattern: regexPattern, options: [])
                let regexResults = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count)) as Array<NSTextCheckingResult>
                for regexResult in regexResults {
                    results?.append((range:self.range(from: regexResult.range)!, substring:self.substring(with: regexResult.range)!))
                    // DLog.misc.info("rangesOfDigits found:\(digitsStr) in \(self) at:\(regexResult.range)")
                }
            } catch let error as NSError {
                MNLog.misc.warning("StringEx.rangesOfDigits excpetion in regex: \(error.description)")
            }
        }
        
        if results?.count == 0 {
            results = nil
        }
        
        return results
    }
    
    /// Returns a copy of the string which omits all charahters that are NOT decimal digits, thus the remainder string is ONLY digits.
    var keepingDigitsOnly : String {
        get {
            return self.replacingOccurrences(of: CharacterSet.decimalDigits.inverted, with: "")
        }
    }
    
    /// Returns the ratio (part out of 1) of digit chars from the count of all chars.
    func partOfDigits()->Float {
        guard self.count > 0 else {
            return 0
        }
        
        let cnt = Float(self.count)
        let digits = Float(self.keepingDigitsOnly.count)
        return digits / cnt
    }
    
    var isAllAlphaNumerics : Bool {
        return self.replacingOccurrences(of: .alphanumerics, with: "").count == 0
    }
    
    var isAllDigits : Bool {
        return self.keepingDigitsOnly.count == self.count
    }
    
    var isAllCharsUppercased : Bool {
        return self.uppercased() == self
    }
    
    var isAllCharsLowercased : Bool {
        return self.lowercased() == self
    }
    
    var isAllCharsAscii : Bool {
        for scalar in self.unicodeScalars {
            if !scalar.isASCII {
                return false
            }
        }
        return true
    }
    
    
    func matchRanges(for regex: String, options: NSRegularExpression.Options = []) -> [NSRange] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regex, options: options)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { $0.range }
        } catch let error {
            print("[StringEx] invalid regex: \(error.localizedDescription) \((error as NSError).debugDescription)")
            return []
        }
    }
    
    func matches(for regex: String, options: NSRegularExpression.Options = []) -> [String] {
        let text = self
        let ranges = self.matchRanges(for: regex, options:options)
        if ranges.count > 0 {
            return ranges.map { (text as NSString).substring(with: $0)}
        }
        
        return []
    }
}


public extension String {
    
    
    /// Capitalizes only the first word in the text
    /// - Returns: a copy of the text with the first word in the text capitalized.
    func capitalizedFirstWord()->String {
        guard self.count > 0 else {
            return self
        }
        
        let comps = self.components(separatedBy: .whitespacesAndNewlines)
        if comps.count > 1 {
            return self.replacingOccurrences(of: comps[0], with: comps[0].capitalized)
        } else {
            return self.capitalized
        }
    }
    /// Substring for a string with a given NSRange
    
    func split(atIndex index:Int)->[String]? {
        if index == 0 {
            return ["", self.substring(from: 1)]
        }
        
        if index == self.count - 1 {
            return [self.substring(upTo: max(self.count - 2, 0)), ""]
        }
        
        if index < self.count && index > 0 {
            return [self.substring(upTo: index), self.substring(from: index + 1)]
        }
        
        return nil
    }
    
    /// Trim a string from either a prefix and / or suffix string
    ///
    /// - Parameter string: a string to trim either from the start or end of the string.
    /// - Returns: a new string with its prefix of suffix or both trimmed, or the original string if the given string is not a prefix nor a suffix
    func trimming(string:String)->String {
        var result = self
        if self == string {
            return ""
        }
        while result.hasPrefix(string) {
            result = self.substring(from: min(string.count, self.count - 1))
        }
        while result.hasSuffix(string) {
            result = self.substring(to: max(result.count - string.count - 1, 0))
        }
        return result
    }
    
//    func indices(of occurrence: String) -> [Int] {
//        var indices = [Int]()
//        var position = startIndex
//        while let range = range(of: occurrence, range: position..<endIndex) {
//            let i = distance(from: startIndex,
//                             to: range.lowerBound)
//            indices.append(i)
//            let offset = occurrence.distance(from: occurrence.startIndex,
//                                             to: occurrence.endIndex) - 1
//            guard let after = index(range.lowerBound,
//                                    offsetBy: offset,
//                                    limitedBy: endIndex) else {
//                                        break
//            }
//            position = index(after: after)
//        }
//        return indices
//    }
//
//    func ranges(of searchString: String) -> [Range<String.Index>] {
//        let _indices = indices(of: searchString)
//        let count = searchString.count
//        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
//    }
    
    func substrings(between prefix:String, suffix:String, isCaseSensitive : Bool = true, innerDelimiter : String? = nil, maxSubstrLength : Int = 256)->[String]? {
        var result : [String] = []
        
        let regex = NSRegularExpression.escapedPattern(for:prefix) + ".{0,\(maxSubstrLength)}" + NSRegularExpression.escapedPattern(for:suffix)
        result = self.matches(for: regex, options: isCaseSensitive ? [] : [.caseInsensitive]).map({ str in
            return str.trimmingPrefix(prefix).trimmingSuffix(suffix)
        })
        
        if let inner = innerDelimiter {
            result = result.flatMap { str in
                return str.components(separatedBy: inner)
            }
        }
        
        /*
        let splitted = self.components(separatedBy: suffix)
        splitted.forEachIndex { index, part in
            if let prefixRange = part.matchRanges(for: prefix).last {
                if let substr = part.split(atIndex: prefixRange.location + prefixRange.length)?.last {
                    result.append(substr)
                }
            }
        }*/
        return result
    }
    
    func hasAnyOfPrefixes(_ prefixes : [String])->Bool {
        for prefix in prefixes {
            if self.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    
    func hasAnyOfSuffixes(_ suffixes : [String])->Bool {
        for suffix in suffixes {
            if self.hasSuffix(suffix) {
                return true
            }
        }
        return false
    }
    
    
    /// Returns a string with multiple successive whitespaces or newlines are condensed into a single space
    /// For example:
    /// "mY TEXT  123\n  \tnew"
    /// will codense into:
    /// "mY TEXT 123 new"
    /// - Returns: a condensed string
    func condenseWhitespacesAndNewlines() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    /// Returns a string with multiple successive whitespaces are condensed to into single space
    /// For example:
    /// "mY TEXT  123\n  \tnew"
    /// will codense into:
    /// "mY TEXT 123\n \tnew"
    /// - Returns: a condensed string
    func condenseWhitespaces() -> String {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    
    /// tries to detect the direction of the best found language is the string
    func detectBestLanguage()->String? {
        guard self.count > 0 else {
            return nil
        }
        
        let substr = self.substring(upTo: 100)
        return CFStringTokenizerCopyBestStringLanguage(substr as CFString, CFRange(location: 0, length: substr.count )) as String?
    }
    
    /// tries to detect the direction of the best found language is the string
    func detectBestTextAlignment()->NSTextAlignment? {
        if let lang = self.detectBestLanguage() {
            let rtlLangs = ["ar", "he"]
            return lang.lowercased().contains(anyOf: rtlLangs) ? .right : .left
        }
        return nil
    }
}

public extension String {
    
    init (memoryAddressOf object:AnyObject) {
        self.init(String(describing: Unmanaged<AnyObject>.passUnretained(object as AnyObject).toOpaque()))
    }
    
    init (memoryAddressOfOrNil object:AnyObject?) {
        guard let object = object else {
            self.init("<nil>")
            return
        }
        self.init(String(describing: Unmanaged<AnyObject>.passUnretained(object as AnyObject).toOpaque()))
    }
    
    
    /// Returns a string describing the memory address of the struct. The struct must be in an mutable state, because this is an inout call
    init<T>(memoryAddressOfStruct structPointer: UnsafePointer<T>) {
        let intValue = Int(bitPattern: structPointer)
        let length = 2 + 2 * MemoryLayout<UnsafeRawPointer>.size
        self.init(format: "%0\(length)p", intValue)
    }
}

public extension Sequence where Element == String {
    var lowercased : [String] {
        return self.compactMap { str in
            return str.lowercased()
        }
    }
    
    var uppercased : [String] {
        return self.compactMap { str in
            return str.lowercased()
        }
    }
    
    func serializationIssuesVariants(maxElements:UInt = 1000)->[String] {
        var result : [String] = []
        for val in self {
            let variants = val.serializationIssuesVariants(isUniquify: false)
            if result.count + variants.count > maxElements {
                MNLog.misc["serializationIssuesVariants"]?.warning("too many variants creatd > \(maxElements) maxElements. enough variants made!")
                break
            } else {
                result.append(contentsOf: variants)
            }
        }
         
        return result.uniqueElements() // keeps order
    }
}

public extension String {
    
    func serializationIssuesVariants(isUniquify : Bool = true)->[String] {
        let result = [self,
                      self.lowercased(),
                      self.uppercased(),
                      self.capitalized,
                      self.camelCaseToSnakeCase(),
                      self.snakeCaseToCamelCase()]
        return isUniquify ? result.uniqueElements() : result
    }
    
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        let result = self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
        return result.replacingOccurrences(of: .whitespacesAndNewlines, with: "_")
    }
    
    fileprivate func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
    
    func snakeCaseToCamelCase() -> String {
        return self.components(separatedBy: "_").capitalized().joined(separator: "").replacingOccurrences(of: .whitespaces, with: "")
    }
}

public extension String /* substring with int ranges */ {
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }

        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }

        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }

        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }

        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }

        return String(self[startIndex ..< endIndex])
    }

    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }

    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }

    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }

        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }

        return self.substring(from: from, to: end)
    }

    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }

        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }

        return self.substring(from: start, to: to)
    }
}

public extension String /* OLD substring with int ranges */ {
    
     
    /// - Parameter range: NSRange for the substring location, assuming utf16 encoding
    /// - Returns: the substring of the string or nil if NSRange is out of bounds
    func substring(with range:NSRange)->String? {
        if range.location >= 0 && range.location + range.length <= self.count, let rng = self.range(from: range) {
            return String(self[rng])
        }
        return nil
    }
    
    func substring(atIndex index:Int)->String? {
        return self.substring(with: NSRange(location:index, length:1))
    }
    
    /// Safe substring
    ///
    /// - Parameter index: index to return a substring that is up to this index, or shorter if the string is shorter
    /// - Returns: either
    func substring(upTo index:Int)->String {
        
        if index < 0 {
            return self.substring(from: max(Int(self.count) + index, 0))
        }
        
        guard
            let strIndex16 = utf16.index(utf16.startIndex, offsetBy: index, limitedBy: utf16.endIndex),
            let strIndex = strIndex16.samePosition(in: self)
            else {return self}
        if self.endIndex > strIndex {
            return String(self[self.startIndex..<strIndex])
        }
        return self
    }
    
    /*
    func substring(from fromIndex:UInt, upTo upToIndex:UInt)->String {
        guard fromIndex < Int.max / 2 && upToIndex < Int.max / 2 else {
            NSLog("[StringEx] substring(from:to:) failed. toIndex or fromIndex too big!")
            return self
        }
        return self.substring(from: Int(fromIndex), upTo: Int(upToIndex))
    }
    
    
    /// Returns a substring using int offsets of the indexes:
    /// - Parameters:
    ///   - fromIndex: starting index for the resulting Substring
    ///   - upToIndex: ending index for the substring to reach up to, but not including its charachter.
    /// - Returns: a substring from the given two int indexes.
    func substring(from fromIndex:Int, upTo upToIndex:Int)->String {
        guard fromIndex < upToIndex else {
            NSLog("[StringEx] substring(from:to:) failed. upToIndex < fromIndex!")
            return self
        }
        return self.substring(withIntRange: fromIndex..<upToIndex)
    }
    
    func substring(withIntRange r: Range<Int>) -> String {
        guard let astrIndex16 = utf16.index(utf16.startIndex, offsetBy: r.lowerBound, limitedBy: utf16.endIndex),
             let astrIndex = astrIndex16.samePosition(in: self) else {
                return ""
        }
        
        guard let bstrIndex16 = utf16.index(utf16.startIndex, offsetBy: r.lowerBound, limitedBy: utf16.endIndex),
            let bstrIndex = bstrIndex16.samePosition(in: self) else {
                return ""
        }
        
        // TODO: Resolve this:
        return String(self[astrIndex..<bstrIndex]) //(with: astrIndex..<bstrIndex)
    }
     */
    
    func substring(untilFirstOccuranceOf substr:String)->String? {
        // TODO: Validate this && write tests
        
        if let range = self.matchRanges(for: substr).first {
            return self.substring(upTo: range.location)
        }
        
        return nil
    }
}

//extension String /* bounding rectangles */ {
//    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
//        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
//        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.height)
//    }
//
//    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
//        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
//        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.width)
//    }
//}

/*
extension String /*run command*/{
    func runAsCommand() -> String {
        let pipe = Pipe()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", String(format:"%@", self)]
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        if let result = NSString(data: file.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
            return result as String
        }
        else {
            return "--- Error running command - Unable to initialize string from file data ---"
        }
    }
}*/
