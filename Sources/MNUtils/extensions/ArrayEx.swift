//
//  ArrayEx.swift
//  testSwift
//
//  Created by Ido Rabin for  on 30/10/2023.
//  Copyright © 2024 Bricks. All rights reserved.
//

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "ArrayEx") // ?.setting(verbose: false, testing: IS_TESTING)

public extension Sequence {
    /// Iterate all elements while handling for each element its index and the element.
    func forEachIndex(_ body: (Int, Element) throws -> Void) rethrows {
        try self.enumerated().forEach { index, element in
            try body(index, element)
        }
    }
    
    var descriptionJoined : String {
        return self.descriptions().descriptionJoined
    }
    
    func descriptions()-> [String] {
        return self.compactMap({ (element) -> String in
            if let element = element as? CustomStringConvertible {
                return element.description
            } else {
                return String(describing: element)
            }
        })
    }
    
    var descriptionLines : String {
        return self.descriptions().descriptionLines
    }
}

public extension Sequence where Element : CustomDebugStringConvertible {

    func debugDescriptions()-> [String] {
        return self.compactMap({ (element) -> String in
            return element.debugDescription
        })
    }
}

public extension Array {
    
    /// Iterate all elements and their preceeding elements (current, previous). Will call first block with items index 0 and nil, next will call items 1 and 0 and so on..
    /// (current, previous) is the order of elements in the completion block
    func forEachAndPrevious(_ body: (Element, Element?) throws -> Void) rethrows {
        
        if self.count == 0 {return}
        var prev : Element? = nil
        for i in 0..<self.count {
            try body(self[i], prev)
            prev = self[i]
        }
    }
    
    /// Iterate all elements while handling for each element its index and the element.
    func forEachIndex(_ body: (Int, Element) throws -> Void) rethrows {
        if self.count == 0 {return}
        
        // TODO: Compare efficiency between .enumerated().forEach and the "for i in ..." loop...
        // self.enumerated().forEach { index, element in
        //     try body(index, element)
        // }
        for i in 0..<self.count {
            try body(i, self[i])
        }
    }
    
    /// Iterate all elements while handling for each element its float (index / total amount) part and the element. Thus serving a float growing on each iteration between 0... to 1.0. Good for calulating progress etc.
    func forEachPart(_ body: (Float, Element) throws -> Void) rethrows {
        if self.count == 0 {return}
        
        let lastIndex = self.count - 1
        for i in 0..<self.count {
            try body(Float(i)/Float(lastIndex), self[i])
        }
    }
    
    
    /// Iterate all elements while handling for each element its index and the element.
    /// - Parameter body: iteration bloc. Return True to stop iterating!
    func forEachIndexOrStop(_ body: (Int, Element) throws -> Bool) rethrows {
        if self.count == 0 {return}
        
        for i in 0..<self.count {
            let stop = try body(i, self[i])
            if stop {
                break
            }
        }
    }
    
    
    func appending(_ element:Element)->Array<Element> {
        var result = self
        result.append(element)
        return result
    }
    
    func appending(contentsOf elements:[Element])->Array<Element> {
        var result = self
        result.append(contentsOf: elements)
        return result
    }
}

public extension Array {
    
    /// Will iterate all elements one by one and compare them with all other elements but themselves, in an eficcient manner
    /// The function will call block with distinct pairs of elements, each pair called only once. (i.e same pair will never appear twice)
    ///
    /// - Parameter block: block to perform when comparing tow different elements
    func iterateComparingAllElements(where block: (_ elementA:Element, _ elementB : Element)->Void) {
        if self.count > 1 {
            for i in 0..<self.count {
                for j in (i+1)..<self.count {
                    block(self[i], self[j])
                }
            }
        } else {
            print("ArrayEx.compareAllElements cannot compare when count < 2")
        }
    }
    
    func removing(at index:Int)->[Element] {
        var result : [Element] = Array(self)
        if (index < 0) {
            result.remove(at: self.count + index) // python style remove from the end when negative...
        } else {
            result.remove(at: index)
        }
        return result
    }
}

public extension Array {

    /// Searches for the biggest slices that match the test
    /// Will attempt to expand each element in both direction until a match is reached. Note that without the stopSliceGrowing test, we will grow slices even if they fail the test, to see if bigger slices pass the test. I.E algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] were not matched as slices and we started growing from wither of those. This means this function may proce CPU intensive.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameters:
    ///   - test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    ///   - stopSliceGrowing: a seperate test that disqualifies a slice from further testing (or gorwing and then more testing). This allows for optimization, and tells the algo when not to grow a slice and test again. NOTE: When this block is nil, the algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] are not matched as slices.
    func searchForConsecutiveSlices(matching test:([Element])->Bool, stopSliceGrowing:(([Element])->Bool)?)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        guard self.count > 0 else {
            return []
        }
        
        var result :[([Element], NSRange)] = []
        
        dlog?.info("\n\n---testing\n\n")
        var maxIdx = 0
        var activeRange : NSRange = NSRange(location: 0, length: 0)
        var lastFoundRange : NSRange = NSRange(location: 0, length: 0)
        var loopProtection = self.count * self.count
        var failedSlice = false
        var testsCount = 0
        var loopCount = 0
        
        while maxIdx < self.count && loopProtection > 0 {
            failedSlice = false
            activeRange = NSRange(location: maxIdx, length: 1)
            var biggestFoundSlice : [Element] = []
            var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
            
            while activeRange.upperBound <= self.count && !failedSlice {
                let sliceToTest = self[activeRange.lowerBound..<Swift.min(activeRange.upperBound, self.count)]
                dlog?.info("testing slice: \(sliceToTest.description)")
                
                testsCount += 1 // total tests count
                if test(Array(sliceToTest)) {
                    // Found
                    biggestFoundSlice = Array(sliceToTest)
                    biggestFoundRange = activeRange
                } else {
                    // Failed
                    if (biggestFoundSlice.count > 0)
                    {
                        failedSlice = true
                    }
                    
                    // Test to stop growing, go to next active range location:
                    if stopSliceGrowing?(Array(sliceToTest)) ?? false {
                        dlog?.info("Will stop growing for slice:\(sliceToTest)")
                        failedSlice = true
                    }
                }
                activeRange.length += 1
                loopCount += 1
            }
            
            if (biggestFoundSlice.count > 0)
            {
                dlog?.info("Found biggest slice in range:\(biggestFoundRange) :\(biggestFoundSlice)")
                if (biggestFoundRange.location > 0 &&
                    lastFoundRange.upperBound != 0 &&
                    biggestFoundRange.location > lastFoundRange.upperBound) {
                    // We should search backwards?
                    var anotherFoundRange = biggestFoundRange
                    failedSlice = false
                    
                    // Test backeards if possible
                    while anotherFoundRange.location > lastFoundRange.upperBound && !failedSlice {
                        anotherFoundRange.location -= 1
                        anotherFoundRange.length += 1
                        dlog?.info("will be testing backwards between prev slice and this slice")
                        if anotherFoundRange.location > -1 {
                            let sliceToTest = self[anotherFoundRange.lowerBound..<Swift.min(anotherFoundRange.upperBound, self.count)]
                            dlog?.info("testing backwards slice: \(sliceToTest.description)")
                            
                            testsCount += 1 // total tests count
                            if test(Array(sliceToTest)) {
                                // Found while adding from the leading edge ("going backwards")
                                biggestFoundSlice = Array(sliceToTest)
                                biggestFoundRange = activeRange
                            } else {
                                // Test to stop growing, go to next active range location:
                                if stopSliceGrowing?(Array(sliceToTest)) ?? false {
                                    dlog?.info("Will stop growing rewind for slice:\(sliceToTest)")
                                    failedSlice = true
                                }
                            }
                        }
                        
                        loopCount += 1
                    }
                }
                
                activeRange.location = biggestFoundRange.upperBound
                activeRange.length = 1
                maxIdx = activeRange.location
                lastFoundRange = biggestFoundRange
                dlog?.info("Adding slice to results:\(biggestFoundRange) :\(biggestFoundSlice)")
                result.append((biggestFoundSlice, biggestFoundRange))
                
            } else {
                dlog?.info("DNF slice in range \(activeRange)")
                maxIdx += 1
            }
            loopProtection -= 1
            loopCount += 1
        }
        
        dlog?.info("Found \(result.count) slices performing \(testsCount) tests and \(loopCount) loops")

        return result
    }
    
    
    /// Searches for the biggest slices that match the test
    /// Will attempt to expand each element in both direction until a match is reached. Note that without the stopSliceGrowing test in another version for this function, we will grow slices even if they fail the test, to see if bigger slices pass the test. I.E algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] were not matched as slices and we started growing from wither of those. This means this function may proce CPU intensive.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesMatching(_ test:([Element])->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        return searchForConsecutiveSlices(matching: test, stopSliceGrowing: nil)
    }
    
    /// Searches for the biggest slices that match the test
    /// This function iterates all elements from left (index 0) to right and crates a "slice" each time the previous element does not pass the test the same way the next eleement does.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesWithElementsMatching(_ test:(Element)->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        var result : [([Element]/* slice */, NSRange /* range of slice*/)] = []
        
        // self.split(maxSplits: Int.max, omittingEmptySubsequences: true, whereSeparator: {(element) in return !test(element)) })
        var biggestFoundSlice : [Element] = []
        var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
        
        for i in 0..<self.count {
            let element = self[i]
            if test(element) {
                biggestFoundSlice.append(element)
                biggestFoundRange.length += 1
            } else {
                if (biggestFoundSlice.count > 0) {
                    result.append((biggestFoundSlice, biggestFoundRange))
                }
                biggestFoundSlice = []
                biggestFoundRange = NSRange(location: i + 1, length: 0)
            }
        }
        
        // Last slice has the ending element
        if (biggestFoundSlice.count > 0) {
            result.append((biggestFoundSlice, biggestFoundRange))
        }
        
        return result
    }
    
    /// Searches for the biggest slices that match the test
    /// This function iterates all elements from left (index 0) to right and crates a "slice" each time the previous element does not pass the test the same way the next eleement does.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesWithElementsPairsMatching(_ test:(/*current*/Element, /*previous*/Element?)->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        var result : [([Element]/* slice */, NSRange /* range of slice*/)] = []
        
        // self.split(maxSplits: Int.max, omittingEmptySubsequences: true, whereSeparator: {(element) in return !test(element)) })
        var biggestFoundSlice : [Element] = []
        var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
        
        for i in 0..<self.count {
            let element = self[i]
            let prev = (i > 0 ? self[i-1] : nil)
            if test(element, prev) {
                if let prev = prev {
                    biggestFoundSlice.append(prev)
                    biggestFoundRange.length += 1
                }
                if prev != nil {
                    biggestFoundSlice.append(element)
                    biggestFoundRange.length += 1
                }
            } else {
                if (biggestFoundSlice.count > 0) {
                    result.append((biggestFoundSlice, biggestFoundRange))
                }
                biggestFoundSlice = []
                biggestFoundRange = NSRange(location: i, length: 0)
            }
        }
        
        // Last slice has the ending element
        if (biggestFoundSlice.count > 0) {
            result.append((biggestFoundSlice, biggestFoundRange))
        }
        
        return result
    }
}

// TODO: See how to do this!

public protocol OptionalType {
  associatedtype Wrapped
  var optionalType: Wrapped? { get }
}

extension Optional: OptionalType {
    public var optionalType: Self { self }
}

public extension Array { // where Element: OptionalType {
    
    /// Mutating: adds the element to the array if it is not nil
    /// - Parameter object: object to append if not nil
    /// - Returns: true when element was added, false when element is nil
    @discardableResult
    mutating func appendIfNotNil(_ object : Element?)->Bool {
        guard let object = object else {
            return false
        }
        
        self.append(object)
        return true
    }
    
}

public extension Array where Element: Equatable & OptionalType {
    /// Mutating: adds the element to the array if it is not nil AND does not already exist in the array (using equatable)
    /// - Parameter object: object to append if not nil AND not already in the array
    /// - Returns: true when element was added, false when element is nil or is equal to an element already  in the array (using equatable)
    @discardableResult
    mutating func appendIfNotAlreadyOrNil(_ object : Element?)->Bool {
        guard let object = object else {
            return false
        }
        
        if !self.contains(object) {
            self.append(object)
            return true
        }
        return false
    }
}

/// Extends the Array class to handle equatable objects, thus allowing remove by object, intersection and testing if elements are common (shared) between two arrays
public extension Array where Element: Equatable {
    
    func find(where test:(_ object:Element)->Bool, found:(_ object:Element)->Void, notFound:()->Void) {
        for object in self {
            if (test(object))
            {
                found(object)
                return
            }
        }
        
        notFound()
    }
    
    /// Mutating: removes all collection element that are equal to the given `object`:
    ///
    /// - Parameter object: object to remove
    /// - Returns: count of removed items
    @discardableResult mutating func remove(elementsEqualTo: Element)->Int {
        var removedCount = 0
        while let index = firstIndex(of: elementsEqualTo) {
            remove(at: index)
            removedCount += 1
        }
        return removedCount
    }
    
    /// Remove elements that are equal to the given `object`:
    ///
    /// - Parameter objects: objects to remove
    /// - Returns: count of removed items
    @discardableResult mutating func remove(objects: [Element])->Int {
        guard objects.count > 0 else {
            return 0
        }
        
        var removedCount = 0
        for object in objects {
            while let index = firstIndex(of: object) {
                remove(at: index)
                removedCount += 1
            }
        }
        return removedCount
    }
    
    /// Remove all objects that match a test
    /// Note: the function will accumulate a temp array of objects before removing them all from the array in one call, so there is a memory penalty sized the amount of objects to be deleted for this function
    ///
    /// - Parameter block: return bool for elements that are to be removed
    /// - Returns: count of elements removed
    @discardableResult
    mutating func remove(where block: (_ object:Element)->Bool)->Int {
        var toRemove : [Element] = []
        for object in self {
            if block(object) {
                toRemove.append(object)
            }
        }
        return self.remove(objects: toRemove)
    }
    
    func removing(elementsEqualTo: Element)->[Element] {
        var result : [Element] = Array(self)
        result.remove(elementsEqualTo: elementsEqualTo)
        return result
    }
    
    func removing(objects: [Element])->[Element] {
        guard objects.count > 0 else {
            return []
        }
        var result : [Element] = Array(self)
        result.remove(objects: objects)
        return result
    }
    
    func removing(where block: (_ object:Element)->Bool)->[Element] {
        var result : [Element] = Array(self)
        result.remove(where: block)
        return result
    }
    
    
    /// Returns true if at least one element is common between the two arrays (appears in both arrays)
    /// NOTE: Uses equatable to check for appearance in both arrays. Will stop evaluating after first match encountered.
    /// - Parameter objects: another array to find an intersection with
    /// - Returns: true if at least one element appears in both arrays
    func intersects(with objects: [Element])->Bool {
        
        if (objects.count == 0 || self.count == 0) { return false } // could never intersect empty array with another array
        
        var result = false
        if let _ = objects.first(where: { item in
            self.contains(item)
        }) {
            // found first item in itersection. that's enough
            result = true
        }
        
        return result
    }
    
    /// Check if the array contains at least one of the elements
    /// - Parameter items: items to find intersection with this array
    /// - Returns: true if at least one item is common / shared between self and the items array
    func contains(anyOf items:[Element])->Bool {
        return self.intersects(with: items)
    }
    
    /// Returns true if the provided element appears in the array (uses Equatable for comparison)
    /// - Parameter element: element to search
    /// - Returns: true when at least one element (or an equal to element) appears in the array
     func contains(elementEqualTo element:Element)->Bool {
        return self.intersects(with: [element])
    }
    
    /// Return a new array of all intersecting objectes between two arrays
    /// For this function, intersecting is tested by using index(of:object) on both arrays, assuming objects are Equatable
    ///
    /// - Parameter objects: another array to intersect with
    /// - Returns: an array with all elements common fo both arrays
    func intersection(with objects: [Element])->[Element] {

        if (objects.count == 0 || self.count == 0) {return []}
        
        let result = objects.filter { (item) -> Bool in
            return self.contains(item)
        }

        return result
    }
    
    /// Returns all elements NOT shared with the given array (will return only elements from the operated upon array which are not in the objects array)
    ///
    /// - Parameter objects: an array of objects to test commonality of objects with
    /// - Returns: all elements NOT shared with the given array (will return only elements from the operated upon array which are not in the objects array)
    func notShared(with objects: [Element])->[Element] {
        
        if (objects.count == 0) {return Array<Element>(self)}
        if (self.count == 0)    {return objects}
        
        let result = self.filter { (item) -> Bool in
            return objects.contains(item) == false
        }

        return result
    }
    
    /// Returns a union between the arrays, keeping previous order and adding only elements that were not contained by the original array. (left-side has priority)
    ///
    /// - Parameter objects: an array of objects to union with
    /// - Returns: all elements in the current aray, and all elements in the objects aray that are not already in the given array.
    func union(with objects: [Element])->[Element] {
        var result : [Element] = []
        result.append(contentsOf: self)
        if objects.count > 0 {
            result.append(contentsOf: objects.notShared(with: self))
        }
        return result
    }
    
    /// Mutating: adds the element to the array if it does not already exist in the array (using equatable)
    /// - Parameter object: object to append if not already in the array
    /// - Returns: ttrue when element was added, false when element is equal to an element already  in the array (using equatable)
    @discardableResult
    mutating func appendIfNotAlready(_ object : Element)->Bool {
        if !self.contains(object) {
            self.append(object)
            return true
        }
        return false
    }
    
    
    /// Returns a new array with the element added to the array if it did not already exist in original array (using equatable)
    /// - Parameter element: element to append if not already in the array
    /// - Returns: new array with element appended (if wan't already in it)
    func appendingIfNotAlready(_ element:Element)->Array<Element> {
        var result = self
        result.appendIfNotAlready(element)
        return result
    }
    
    
    @discardableResult
    /// Append to the array if a condition is met
    /// - Parameters:
    ///   - test: a test block that recieves the element as the parameter and returns true when the element needs to be appended to the array
    ///   - object: element that is being tested if it should be added
    /// - Returns: true if element was added, false if failed the test
    mutating func appendIf(test:Bool, _ object : Element?)->Bool {
        guard let object = object, test == true else {
            return false
        }
        
        self.append(object)
        return true
    }
    
    /// Will replace any occurance of Equatable elements equal to element with the given array of elements inserted in its place
    /// - Parameter element: element to replace
    /// - Parameter with: elements to instert is all locations where element appeared
    /// - Returns: count of replacements performed
    @discardableResult mutating func replace(_ element:Element, with others:[Element])->Int {
        guard others.contains(element) == false else {
            print("WARNING ❌ ArrayEX (Equatable) replace:element:with:[] failed replacing \(element) with array:\(others.description) - this array contains the same (or equatably same) item we are replacing..")
            return 0
        }
        var result = 0
        while let index = self.firstIndex(of: element) {
            self.remove(at: index)
            self.insert(contentsOf: others, at: index)
            result += 1
        }
        return result
    }
    
    /// Will replace any occurance of Equatable elements equal to element with the given array of elements inserted in its place
    /// - Parameter element: element to replace
    /// - Parameter with: elements to instert is all locations where element appeared
    /// - Returns: count of replacements performed
    @discardableResult mutating func replace(_ element:Element, with other:Element)->Int {
        return self.replace(element, with: [other])
    }
    
    @discardableResult mutating func replace(where test:(Element)->Bool, with other:Element)->Int {
        var result = 0 // count of replacements performed
        
        for idx in 0..<self.count {
            if test(self[idx]) {
                // Replace if needed.
                // count or order do not change so we can do this in-loop:
                self[idx] = other
                result += 1 // was replaced
            }
        }
        
        return result
    }
}

public extension Array where Element : Equatable & Hashable {
    
    /// Returns an array with the elements in the same order, only removing duplicate elements (equatables)
    /// - Returns: The resulting array maintains the order, only removes elements
    func uniqueElements()->[Element]{
        var added = Set<Element>()
        var result : [Element] = []
        for item in self {
            if !added.contains(item) {
                added.update(with: item)
                result.append(item)
            }
        }
        return result
    }
}

public extension Sequence {
    
    func toDictionary<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:Element] {
        var result :[T:Element] = [:]
        for item in self {
            if let key = keyForItem(item) {
                result[key] = item
            }
        }
        return result
    }
    
    func toDictionary<T:Hashable,Z>(keyForItem:(_ element:Element)->T?, itemForItem:(_ key:T, _ element:Element)->Z?)-> [T:Z] {
        var result :[T:Z] = [:]
        for item in self {
            if let key = keyForItem(item),  let resitem = itemForItem(key, item) {
                result[key] = resitem
            }
        }
        return result
    }
    
    
    func groupBy<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:[Element]] {
        return toDictionaryOfArrays(keyForItem: keyForItem)
    }
    
    // AKA groupBy
    func toDictionaryOfArrays<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:[Element]] {
        var result :[T:[Element]] = [:]
        for item in self {
            if let key = keyForItem(item) {
                var arr : [Element] = result[key] ?? []
                arr.append(item)
                result[key] = arr
            }
        }
        return result
    }
    
    func toDictionaryOfArrays<T:Hashable, Elem:Any>(keyForItem:(_ element:Element)->T?, arrayItemForItem:(_ element:Element)->Elem?)-> [T:[Elem]] {
        var result :[T:[Elem]] = [:]
        for item in self {
            if let key = keyForItem(item), let arrItem = arrayItemForItem(item) {
                var arr : [Elem] = result[key] ?? []
                arr.append(arrItem)
                result[key] = arr
            }
        }
        return result
    }
    
    func iterateRollingWindow(windowSize maxSize:Int, block:([Element])->Void) {
        var arr : [Element] = []
        for item in self {
            arr.append(item)
            if arr.count > maxSize {
                arr.removeFirst()
            }
            block(arr)
        }
    }
}

public extension Sequence where Element : Sequence {
    
    
    /// Returns a flat array from all internal arays concatuated.
    var flattened : [Element.Element] {
        return self.flatMap { $0 }
    }
}

public extension Sequence where Element == String {
    
    ///
    /// // Note: test order is according to array order, and will stop testing after first found item
    /// - Parameter items:items to look for in the string.
    ///
    
    
    /// Returns true is this string array contains the given string
    /// - Parameters:
    ///   - string: string to search for in the array
    ///   - isCaseSensitive: determines if the search should be case sensitive or not
    /// - Returns: true if the given string was found in this array
    func contains(_ string : String, isCaseSensitive:Bool = true)->Bool {
        return self.first(where:{ str in
            if isCaseSensitive {
                return str == string
            } else {
                return str.caseInsensitiveCompare(string) == .orderedSame
            }
        }) != nil
    }
    
    /// Returns true if any of the items in the array contain any of the items in the items parameterr as a substring or a whole string.
    ///  - only one successful find is needed to return true.
    ///  NOTE: Wors case complexity is O(n^2)
    /// - Parameters:
    ///   - items: items to search for
    ///   - isCaseSensitive: determines if the search should be case sensitive or not
    /// - Returns: true when at least one item in the array contains at least one item from the items parameter (as a substring)
    func contains(anyOf items:[String], isCaseSensitive:Bool = true)->Bool {
        for str in self {
            if str.contains(anyOf: items, isCaseSensitive: isCaseSensitive) {
                return true
            }
        }
        return false
    }
    
    
    
    /// Returns true if among the items in the array there is at least one instance eual to each of the items in the items parameterr
    ///  - even a single string in items missing from self will break and fail the test
    ///  NOTE: Wors case complexity is O(n^2)
    /// - Parameters:
    ///   - items: items to search for
    ///   - isCaseSensitive: determines if the search should be case sensitive or not
    /// - Returns: true when at the array contains all of the items in the items parameter
    func contains(allOf items:[String], isCaseSensitive:Bool = true)->Bool {
        for item in items {
            if !self.contains(item, isCaseSensitive: isCaseSensitive) {
                return false // one of the substrings is missing in the array
            }
        }
        return true // contains all
    }
    
    /// Returns all strings in the array containing the provided substring (and their indexes)
    /// - Parameters:
    ///   - substring: substring to search for within each string element in the array
    ///   - isCaseSensitive: compares substring using case sensitivity (default is true)
    /// - Returns: a dictionary of string elements from the array (containing the substring) by their index in the array
    func stringsContainingSubstring(_ substring : String, isCaseSensitive:Bool = true)->[Int:String] {
        var result : [Int:String] = [:]
        self.forEachIndex { index, str in
            if str.contains(substring, isCaseSensitive: isCaseSensitive) {
                result[index] = str
            }
        }
        return result
    }
    
    /// Returns all indexes of strings in the array containing the provided substring
    /// - Parameters:
    ///   - substring: substring to search for within each string element in the array
    ///   - isCaseSensitive: compares substring using case sensitivity (default is true)
    /// - Returns: an array of all indexes where the string element in the array contained the searched substring
    func indexesContainingSubstring(_ substring : String, isCaseSensitive:Bool = true)->[Int] {
        var result : [Int] = []
        self.forEachIndex { index, str in
            if str.contains(substring, isCaseSensitive: isCaseSensitive) {
                result.append(index)
            }
        }
        return result
    }
    
    /// Returns true if at least one string in the array contains the provided substring in it
    /// - Parameters:
    ///   - substring: substring to search for within each string element in the array
    ///   - isCaseSensitive: compares substring using case sensitivity (default is true)
    /// - Returns: true when the searched substring appears at least once in the array
    func containsSubstring(_ substring : String, isCaseSensitive:Bool = true)->Bool {
        return self.first(where:{ str in
            return str.contains(substring, isCaseSensitive: isCaseSensitive)
        }) != nil
    }
    
    
    /// Will reove all strings from the array that are equal to one of the strings in the provided strings array.
    /// NOTE: will check for equality with or without case sensitivity, but will not remove when strings contain a substring of self
    /// - Parameters:
    ///   - strings: strings to remove from the array.
    ///   - isCaseSensitive: determines if  the check for removal be case sensitive or not
    /// - Returns: A string array comprised of all the original elements, minus those elements which are contained to one of the provided string.
    func removing(strings: [Element], isCaseSensitive:Bool = true)->[Element] {
        var result : [Element] = Array(self)
        result.removeAll { elem in
            strings.contains(elem, isCaseSensitive: isCaseSensitive)
        }
        return result
    }
}

public extension Sequence where Element : RawRepresentable {
    var rawValues : [Element.RawValue] {
        return self.map { val in
            val.rawValue
        }
    }
}


public enum SequenceMajorityVoteFallback : Int, Equatable, CaseIterable {
    case first = 1
    case second = 2
}

public extension Array where Element : Equatable {
    
    func majorityValue(whenTwoVals:SequenceMajorityVoteFallback = .first)->Element? {
        guard self.count > 0 else {
            return nil
        }
        
        var result : Element? = self.first
        let arr = self.groupBy { element in
            "key.\(element)"
        }.valuesArray.sorted { arr1, arr2 in
            return arr1.count > arr2.count
        }
        
        switch arr.count {
        case 0:
            result = nil
        case 1:
            result = arr.first?.first
        default:
            result = arr[0].first
            if arr[0].count == arr[1].count {
                switch whenTwoVals {
                case .second: result = arr[1].first
                case .first:
                    break
                }
            }
        }
        
        dlog?.verbose("[\(Element.self)].majorityValue(...) array of values: \(arr) result: \(result.descOrNil)")
        return result
    }
}
