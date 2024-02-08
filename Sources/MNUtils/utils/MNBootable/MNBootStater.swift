//
//  MNBootStater.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNBootStater") // ?.setting(verbose: true)

public protocol MNBootStaterProtocol<ObjectType> {
    associatedtype ObjectType
    
    var state : MNBootState { get }
    var observers : ObserversArray<any MNBootStateObserver<ObjectType>> { get }
    var app : AnyObject? { get }
    var originObject : ObjectType? { get }
    
}

public class MNBootStater<TObject:AnyObject> : MNBootStaterProtocol {

    public typealias ObjectType = TObject
    public typealias ObserverType = MNBootStateObserver<TObject>
    
    private struct MNBootEvent {
        let block : (_ t:TObject, _ app:AnyObject) throws ->Void
        let isClears : Bool
    }
    
    // MARK: Private properties
    public weak var app : AnyObject? = nil
    public weak var originObject : ObjectType? = nil
    private var whenEvents : [MNBootState : [MNBootEvent]] = [:]
    private var _state : MNBootState = .unbooted
    public var _isNeedsSaving: Bool = false
    public var label : String? = nil
    
    // MARK: Public properties
    public let observers = ObserversArray<any ObserverType>()
    public var state : MNBootState {
        get {
            return _state
        }
        set {
            if newValue != _state {
                let oldValue = _state
                do {
                    _state = newValue
                    dlog?.info("\(self.logLabel()) Changing state from \(oldValue) to \(newValue)")
                    try performStateChange(old:oldValue, new:newValue)
                    try performWhenEvents(old:oldValue, new:newValue)
                } catch let error {
                    dlog?.warning("\(self.logLabel()) failed boot state change from: \(oldValue) to: \(newValue). Error: \(error)")
                }
            }
        }
    }
    public var isNeedsSaving: Bool {
        get {
            return _isNeedsSaving
        }
        set {
            if _isNeedsSaving != newValue {
                _isNeedsSaving = newValue
                
                guard let object = originObject else {
                    dlog?.notice("set isNeedsSaving: originObject not defined for MNBootStater")
                    return
                }
                guard let app = self.app else {
                    dlog?.notice("set isNeedsSaving: app not defined for MNBootStater")
                    return
                }
                if newValue {
                    observers.enumerateOnCurrentThread { observer in
                        observer.needsSaving(object: object, inApp: app)
                    }
                    // Cannot call when events, because _isNeedsSaving is not a state in MNBootState
                }
            }
        }
    }
    
    // MARK: Convenience properties
    public var observersCount : Int {
        return self.observers.count
    }
    public var whenEventsCount : Int {
        var result = 0
        for ( _ /* key */ , arr) in whenEvents {
            result += arr.count
        }
        return result
    }
    
    // MARK: Lifecycle
    
    public init() {
        // Empty init - required instantiator to set app and originObject by itself
    }
    /// Initialize the MNBootStater class
    /// - Parameters:
    ///   - originObject: The owner, or object that changes state and for which the state change notifications refer to.
    ///   - app: The currently running app instance (considering various platforms)
    public init(originObject: ObjectType? = nil, app: AnyObject? = nil, label:String? = nil) {
        self.app = app
        self.originObject = originObject
        
        if label == nil, let originObject = originObject {
            self.label = "\(type(of:originObject))"
        } else {
            self.label = label
        }
    }
    
    // MARK: Private funcs
    private func performStateChange(old:MNBootState, new:MNBootState) throws {
        let err : Error? = nil
        guard let object = originObject else {
            dlog?.notice("performStateChange: originObject not defined for MNBootStater")
            return
        }
        guard let app = self.app else {
            dlog?.notice("performStateChange: app not defined for MNBootStater")
            return
        }
        
        dlog?.info("\(self.logLabel())   notifying \(self.observers.count) observers:")
        
        observers.invalidate()
        observers.enumerateOnCurrentThread { observer in
            switch (old, new) {
            case (.unbooted, .booting):
                observer.willBoot(object: object, inApp: app)
            case (.booting, .running):
                observer.didBoot(object: object, inApp: app)
            case (.running, .saving):
                observer.willSave(object: object, inApp: app)
            case (.saving, .running):
                observer.didSave(object: object, inApp: app)
            case (.running, .loading):
                observer.willLoad(object: object, inApp: app)
            case (.loading, .running):
                observer.didLoad(object: object, inApp: app)
            case (_, .shuttingDown):
                observer.willShutdown(object: object, inApp: app)
            case (_, .shutDown):
                observer.didShutdown(object: object, inApp: app)
            default:
                break
            }
        }
        
        // Rethrow
        if let err = err {
            throw err
        }
    }
    
    private func performWhenEvents(old:MNBootState, new:MNBootState) throws {
        guard !self.whenEvents.isEmpty else {
            return
        }
        
        guard var events = self.whenEvents[new], events.count > 0 else {
            return
        }
        guard let obj = originObject, let app = app else {
            return
        }
        
        dlog?.info("\(self.logLabel()) calling \(events.count) call blocks:")
        var indexesToRemove : [Int] = []
        try events.forEachIndex { index, event in
            try event.block(obj, app)
            if event.isClears {
                indexesToRemove.append(index)
            }
        }
        for index in indexesToRemove.reversed() {
            events.remove(at: index)
        }
        if indexesToRemove.count > 0 || events.count != (self.whenEvents[new]?.count ?? 0) {
            // Was changed
            self.whenEvents[new] = events // after being manipulated
        }
    }
    
    // MARK: Public funcs
    public func labelString()->String {
        return label ?? "Unknown"
    }
    
    public func logLabel()->String {
        return "for \(self.labelString()) | "
    }
    
    public func clear() {
        self.observers.clear()
        self.whenEvents = [:]
    }
    
    public func invalidate() {
        self.observers.invalidate()
    }
    
    public func add(observers new: [any ObserverType]) {
        self.observers.add(observers: new)
    }
    
    public func remove(observers old: [any ObserverType]) {
        self.observers.remove(observers: old)
    }
    
    public func add(observer new: any ObserverType) {
        self.observers.add(observer: new)
    }
    
    public func remove(observer old: any ObserverType) {
        self.observers.remove(observer: old)
    }
    
    public func listObservers()->[any ObserverType] {
        return self.observers.list()
    }
    
    public func when(state:MNBootState, perform block:@escaping (_ t:TObject, _ app:AnyObject) throws ->Void, isClears:Bool) {
        var events = whenEvents[state] ?? []
        events.append(MNBootEvent(block: block, isClears: isClears))
    }
}
