//
//  ObserversArray.swift
//  Bricks
//
//  Created by Ido Rabin for Bricks on 30/10/2017.
//  Copyright © 2017 Bricks. All rights reserved.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("ObserversArray")

public class ObserversArrayLock : NSLock {
    fileprivate static let DEBUG_LONG_LOCKS = false
    fileprivate static var locksDebugged : [String] = []
    
    public func lockBlock(_ block:()->Void) {
        
        #if DEBUG
            let memStr = String(memoryAddressOf: self)
            var wasLong = false
        
            // Debug LONG LOCKS
            if ObserversArrayLock.DEBUG_LONG_LOCKS == true {
                DispatchQueue.global().async {
                    ObserversArrayLock.locksDebugged.append(memStr)
                }
                DispatchQueue.global().asyncAfter(delayFromNow: 6.0, block: {
                    if ObserversArrayLock.locksDebugged.contains(memStr) {
                        wasLong = true
                        // dlog?.warning("DEADLOCK? lockBlock is locked for more than 6.0 seconds. Is this planned? Pause to see blocked threads. memStr:\(memStr)")
                    }
                })
            }
        #endif
        
        if self.try() {
            block()
            self.unlock()
        } else {
            dlog?.warning("ObserversArrayLock already locked!!")
        }
        
        #if DEBUG
            if ObserversArrayLock.DEBUG_LONG_LOCKS == true {
                DispatchQueue.global().async {
                    ObserversArrayLock.locksDebugged.remove(elementsEqualTo:memStr)
                    
                }
                
                DispatchQueue.global().asyncAfter(delayFromNow: 6.03, block: {
                    if wasLong {
                        // dlog?.success("lockBlock was unlocked. memStr:\(memStr)")
                    }
                })
            }
        #endif
    }
}

public protocol Observer : AnyObject {
    
}

/// A class to manage an array of weakly referenced array of observers
/// Note that T is expected to be a (delegate) protocol, NOT a class type
/// Note that the observers are expected to be classes or structs who conform to protocol T
/// All observers are assumed to be of AnyObject type at least.
public class ObserversArray <T> {
    // MARK: Properties
    private var weakObservers = WeakArray<AnyObject>()
    private var lock : ObserversArrayLock = ObserversArrayLock()
    var isInvalidatesEagerly = true // After every action, not just after count
    
    // MARK: Private
    /// Cast an observer as any object
    ///
    /// - Parameter observer: observer to be cast
    /// - Returns: AnyObject cast of the observer, assuming it sonforms to AnyObject
    private class func castAsAnyObject(observer: T)->AnyObject? {
        let result = (observer as? AnyObject)   // Warning is Expected, cannot be suppressed.
        if result == nil && MNUtils.debug.IS_DEBUG {
            dlog?.note("castAsAnyObject(\(observer) conforms to \(T.self) but is not a class object / AnyObject")
            return nil
        }
        return result
    }
    
    // MARK: Lifecycle
    public init() {
        
    }
    
    deinit {
        self.clear()
    }
    
    // MARK: Public
    public var count : Int {
        get {
            var result : Int = 0
            self.invalidate() // Will clear all nil weak observeres that have been released
            lock.lock {
                result = weakObservers.count
            }
            return result
        }
    }
    
    public func invalidate() {
        // Enumerating in reverse order prevents a race condition from happening when removing elements.
        lock.lock {
            for (index, observerInArray) in self.weakObservers.enumerated().reversed() {
                // Since these are weak references, "value" may be nil
                // at some point when ARC is 0 for the object.
                if observerInArray.value == nil {
                    // Else, ARC killed it, get rid of the element from our
                    // array
                    self.weakObservers.remove(at:index)
                }
            }
        }
    }
    
    /// Add observers objects to the Array (if not already in it)
    ///
    /// - Parameter observers: observers to be added, assumed to conform with protocol T
    public func add(observers: [T]) {
        lock.lockBlock {
            for observer in observers {
                // If observer is a class, add it to our weak reference array
                if let observerObj = ObserversArray.castAsAnyObject(observer: observer) {
                    var isAlreadyExists = false
                    for (_, observerInArray) in self.weakObservers.enumerated() {
                        // If we have a match, do not add same object twice
                        if observerInArray.value === observerObj {
                            isAlreadyExists = true
                            break
                        }
                    }
                    
                    if (!isAlreadyExists) {
                        self.weakObservers.append(Weak(value: observerObj))
                        if isInvalidatesEagerly {
                            self.invalidate()
                        }
                    }
                } else {
                    // Observer being passed is "by value" (not supported)
                    dlog?.raisePreconditionFailure("does not support value types")
                     fatalError("ObserversArray does not support value types")
                }
            }
        }
    }
    
    public func array()->[T] {
        var result : [T] = []
        self.enumerateOnCurrentThread { (observer) in
            result.append(observer)
        }
        return result
    }
    
    public func list()->[T]
    {
        return self.array()
    }
    
    /// Add an observer object to the Array (if not already in it)
    ///
    /// - Parameter observer: observer to be added, assumed to conform with protocol T
    public func add(observer: T) {
        if isInvalidatesEagerly {
            self.invalidate()
        }
        self.add(observers: [observer])
    }
    
    /// Clear all observers in this ObserversArray instance
    public func clear() {
        lock.lockBlock {
            self.weakObservers.removeAll()
        }
    }
    
    /// Remove an observer object from the Array (if not already amiss)
    ///
    /// - Parameter observer: observer to remove
    public func remove(observer: T) {
        self.remove(observers:[observer])
        
        // DEPRECATED:
//        if isInvalidatesEagerly {
//            self.invalidate()
//        }
//
//        // If observer is an object, let's loop through weakObseervers to
//        // find it.  We
//        lock.lockBlock {
//            if let observerObj = ObserversArray.castAsAnyObject(observer: observer) {
//                for (index, observerInArray) in self.weakObservers.enumerated().reversed() {
//                    // If we have a match, remove the observer from our array
//                    if observerInArray.value === observerObj {
//                        self.weakObservers.remove(at:index)
//                    }
//                }
//            }
//
//            // Else, it's a value type and we don't need to do anything
//        }
    }
    
    public func remove(observers toRemove: [T]) {
        
        if isInvalidatesEagerly {
            self.invalidate()
        }
        
        // If observer is an object, let's loop through weakObseervers to
        // find it.
        var indexesToRemove : [Int] = []
        lock.lockBlock {
            let runSequence = self.weakObservers.enumerated()
            for (index, weakObserver) in runSequence {
                for observer in toRemove {
                    if let observerObj = ObserversArray.castAsAnyObject(observer: observer) {
                        if weakObserver.value === observerObj {
                            indexesToRemove.append(index)
                        }
                    }
                }
            }
            for index in indexesToRemove.reversed() {
                self.weakObservers.remove(at: index)
            }
        }
    }
    
    /// Determine if an observer is already in the observers array
    ///
    /// - Parameter observer: observer to test for presence in the array
    /// - Returns: true when observer is already part of this ObserversArray instance
    public func containsObserver(observer: T)->Bool {
        var result = false
        // If observer is an object, let's loop through weakObservers to
        // find it.  We
        lock.lockBlock {
            if let observerObj = ObserversArray.castAsAnyObject(observer: observer) {
                for (_ , observerInArray) in self.weakObservers.enumerated().reversed() {
                    // If we have a match, remove the observer from our array
                    if observerInArray.value === observerObj {
                        result = true
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    /// Enumerate all observers in this array on the main thread
    /// - Parameters:
    ///   - block: a block for the caller to handle each observer at a time (will be called on mainThread) - (syncs / blocks the calling queue)
    ///   - completed: when all observers have been called on the main thread, this block is called on the original thread
    public func enumerateOnMainThread(block:@escaping (_ observer:T)->Void, completed : (()->Void)? = nil) {
        
        if (Thread.isMainThread) {
            self.enumerateOnCurrentThread(block: block)
            return
        }
        
        func exec() {
            self.lock.lockBlock {
                
                // Enumerating in reverse order prevents a race condition from happening when removing elements.
                for (index, observerInArray) in self.weakObservers.enumerated().reversed() {
                    // Since these are weak references, "value" may be nil
                    // at some point when ARC is 0 for the object.
                    if let observer = observerInArray.value {
                        block(observer as! T)
                    } else {
                        // Else, ARC killed it, get rid of the element from our
                        // array
                        self.weakObservers.remove(at:index)
                    }
                }
            } // Unlock
        }
        
        #if VAPOR
            // NIO. Sync threads main does not work:
            exec()
        #else
        DispatchQueue.main.safeSync {
            exec()
        }
        #endif
        
            
        // Call completion on the current thread
        completed?()
        
    }
    
    /// Enumerate all observers in this array on the current thread
    /// - Parameters:
    ///   - block: a block for the caller to handle each observer at a time (will be called on current thread / queue)
    ///   - completed: when all observers have been called, this block is called on the original thread
    public func enumerateOnCurrentThread(block:(_ observer:T)->Void, completed : (()->Void)? = nil) {
        self.lock.lockBlock {
            
            // Enumerating in reverse order prevents a race condition from happening when removing elements.
            for (index, observerInArray) in self.weakObservers.enumerated().reversed() {
                // Since these are weak references, "value" may be nil
                // at some point when ARC is 0 for the object.
                if let observer = observerInArray.value {
                    block(observer as! T)
                } else {
                    // Else, ARC killed it, get rid of the element from our
                    // array
                    self.weakObservers.remove(at:index)
                }
            }
        }// Unlock
        
        // Call completion on the current thread
        completed?()
    }

    /// Enumerate all observers in this array on a given dispatchQueue thread
    /// - Parameters:
    ///   - queue: the queue on which all the observers should be called
    ///   - block: a block for the caller to handle each observer at a time (will be called on the givven queue)
    ///   - completed: when all observers have been called, this block is called on the original thread
    public func enumerateOnQueue(queue:DispatchQueue, block:@escaping(_ observer:T)->Void, completed : (()->Void)? = nil) {
        queue.safeSync {
            self.lock.lockBlock {
                
                // Enumerating in reverse order prevents a race condition from happening when removing elements.
                for (index, observerInArray) in self.weakObservers.enumerated().reversed() {
                    // Since these are weak references, "value" may be nil
                    // at some point when ARC is 0 for the object.
                    if let observer = observerInArray.value {
                        block(observer as! T)
                    } else {
                        // Else, ARC killed it, get rid of the element from our
                        // array
                        self.weakObservers.remove(at:index)
                    }
                }
            } // Unlock
        }
        
        // Call completion on the current thread
        completed?()
    }
}

extension ObserversArray : CustomStringConvertible {
    public var description : String {
        return "ObserversArray<\(T.self) : \( String(memoryAddressOf: self)) count: \(self.count) >"
    }
    
    public var descriptionListObservers : String {
        var strs : [String] = [self.description]
        self.enumerateOnMainThread { (observer) in
            strs.append("\(observer)")
        }
        return strs.joined(separator: "\n")
    }
}

// TODO: Make sutre this works correctly : test!
public class CodableObserversArray<T:Codable> : ObserversArray<T>, Codable {
    // MARK: Coding keys
    public enum CodingKeys : String, CodingKey, CaseIterable {
        case observers = "observers"
        case isInvalidatesEagerly = "is_invalidates_eagerly"
    }
    
    public func encode(to encoder: Encoder) throws {
        self.invalidate()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.list(), forKey: .observers)
        try container.encode(isInvalidatesEagerly, forKey: .isInvalidatesEagerly)
    }
    
    required public init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isInvalidatesEagerly = try container.decode(Bool.self, forKey: .isInvalidatesEagerly)
        let list = try container.decode([T].self, forKey: .observers)
        // list.forEach { item in
        //    item... do something?
        //}
        self.add(observers: list)
        
    }
}


/// An observerArray which does not encode or decode as anything, but conforms to coding,
/// Assentially making this subclass (when it functions as a property) as a "SkipEncoding" property (see SkipEncoding.swift)
public class SkipCodedObserversArray <T:Observer> : ObserversArray<T>, Codable {
    
    public func encode(to encoder: Encoder) throws {
        // does nothing
    }
    
    public required init(from decoder: Decoder) throws {
        // does nothing
    }
    
    override init() {
        super.init()
    }
}
