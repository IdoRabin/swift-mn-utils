//
//  WeakSet.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "WeakSet")

class WeakSet<T: AnyObject, WeakType: Weakable> where T : Equatable & Hashable {
    typealias WeakedT = WeakHashable<T>
    private var objects: Set<WeakedT>
    
    // Will automatically remove nillified weaks from the set
    // aftr many CRUD calls As a side effect
    var isShouldCompactAfterCRUD : Bool = true
    
    init() {
        self.objects = Set<WeakedT>([])
    }

    var count : Int {
        self.objects.count
    }
    
    init(objects: [T]) {
        self.objects = Set<WeakHashable<T>>(objects.map { WeakedT(value: $0) })
    }

    var values: [T] {
        return objects.compactMap { $0.value }
    }
    
    func contains(value: T) -> Bool {
        return self.objects.contains(WeakedT(value: value))
    }

    func add(value: T) {
        self.objects.update(with: WeakedT(value: value))
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
    }

    func add(values: [T], filteredBy block:((T)->Bool)? = nil) {
        var vals = values
        if let block = block {
            vals = vals.filter({ val in
                return block(val)
            })
        }
        
        guard vals.count > 0 else {
            return
        }
        
        // Validate dupliactes
        if MNUtils.debug.IS_DEBUG {
            let intersection = self.values.intersection(with: vals)
            if intersection.count > 0 {
                dlog?.notice("WeakSet add(values:filteredBy) contains items already in the set: \(intersection.descriptionJoined)")
                // vals.remove(objects: intersection)
            }
        }
        
        // dlog?.info("adding: \(vals.descriptionJoined) into Weak >> \(objects.values.descriptionJoined)")
        let valsToAdd = vals.compactMap { WeakedT(value: $0) }
        // let newObjects = self.objects.union(valsToAdd)
        self.objects.formUnion(valsToAdd)
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
    }
    
    @discardableResult
    func remove(value: T) -> Int {
        return self.remove(values: [value])
    }
    
    @discardableResult
    func remove(values: [T], filteredBy block:((T)->Bool)? = nil) -> Int {
        let prev = self.objects.count
        var vals = values
        if let block = block {
            vals = vals.filter({ val in
                return block(val)
            })
        }
        for value in vals {
            self.objects.remove(WeakedT(value: value))
        }
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
        
        return max(self.objects.count - prev, 0)
    }
    
    @discardableResult
    func remove(where block: (_ value : T)->Bool) -> Int {
        let prev = self.objects.count
        for weakVal in self.objects.reversed() {
            if let val = weakVal.value, block(val) {
                self.objects.remove(weakVal)
            }
        }
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
        
        return max(self.objects.count - prev, 0)
    }
    
    func filter(where block: (_ value : T)->Bool) -> [T] {
        var result : [T] = []
        for weakVal in self.objects {
            if let val = weakVal.value, block(val) {
                result.append(val)
            }
        }
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
        
        return result
    }
    
    func filterWeak(where block: (_ value : T)->Bool) -> [Weak<T>] {
        var result : [WeakedT] = []
        for weakVal in self.objects {
            if let val = weakVal.value, block(val) {
                result.append(weakVal)
            }
        }
        
        // Finally cleanup:
        if isShouldCompactAfterCRUD {
            self.invalidateNillifiedWeaks()
        }
        
        return result.compactMap{ Weak(value: $0.value) }
    }
    
    func compactMap(where block: (_ value : T)->Bool) -> [T] {
        return self.filter(where: block)
    }
    
    func compactMapWeak(where block: (_ value : T)->Bool) -> [Weak<T>] {
        return self.filterWeak(where: block)
    }
    
    /// Mutate the array so that all nilified Weak elements are removed from it
    /// - Returns: count of elements that were of nil value and released
    @discardableResult
    func compactNillifiedWeaks() -> Int {
        var result = 0
        objects.reversed().forEach { elem in
            if elem.value == nil {
                objects.remove(elem)
                result += 1
            }
        }

        return result
    }
    
    // Convenience
    /// Mutate the array so that all nilified Weak elements are removed from it
    /// - Returns: count of elements that were of nil value and released
    @discardableResult
    func invalidateNillifiedWeaks() ->Int {
        return self.compactNillifiedWeaks()
    }
    
    // Convenience
    /// Mutate the array so that all nilified Weak elements are removed from it
    /// - Returns: count of elements that were of nil value and released
    @discardableResult
    func reapNillifiedWeaks () ->Int {
        return self.compactNillifiedWeaks()
    }
}
