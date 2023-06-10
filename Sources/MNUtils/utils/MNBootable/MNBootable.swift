//
//  MNBootable.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNBoot")?.setting(verbose: true)

//  --    --  #if canImport(UIKit)
//#if canImport(vapor) || VAPOR || NIO
//    import Vapor
//    public typealias AppType = Vapor.Application
//#elseif os(OSX)
//    import AppKit
//    public typealias AppType = NSApplication
//#elseif os(iOS)
//    import AppKit
//    public typealias AppType = UIApplication
//#endif
//public var AppType : Any.Type = AnyObject.self
//public func MNSetAppType(_ type : Any.Type) {
//    AppType = type
//}

public enum AppType {
    case VaporServerApp // Vapor.Application
    case MacOSNSApp // NSApplication
    case iOSUIApp  // UIApplication
}


/// Apply this protocol on the object that needs to have lifecycle states and notifications
/// The protocol centers around requiring a bootStater object property for the object. The rest are convenience variables
public protocol MNBootable : AnyObject {
    
    var bootStater : MNBootStater<Self>! { get }
    var bootState : MNBootState { get set }
    
    var isInitializing : Bool { get }
    var isBooting : Bool { get }
    var isInitialized : Bool { get }
    
    var isSaving : Bool { get }
    
    var isLoading : Bool { get }
    
    var isRunning : Bool { get }
    var isShuttingdown : Bool { get }
    
    // Any state other than running:
    var isUnavailable : Bool { get }
}

public extension MNBootable /* default implementation */{
    // bootStater needs to be manually added by the implementor
    
    var bootState : MNBootState {
        get{
            return self.bootStater.state
        }
        set {
            self.bootStater.state = newValue
        }
    }
    
    var isInitializing : Bool {
        return [MNBootState.unbooted, .booting].contains(self.bootState)
    }
    var isBooting : Bool {
        return self.isInitializing
    }
    var isInitialized : Bool {
        if self.bootState == .running {
            dlog?.note("isInitialized but busy doing: \(self.bootState)")
        }
        
        return ![MNBootState.unbooted, .booting].contains(self.bootState)
    }
    var isRunning : Bool {
        return self.bootState == .running
    }
    var isSaving : Bool {
        return self.bootState == .saving
    }
    var isLoading : Bool {
        return self.bootState == .loading
    }
    
    var isShuttingdown : Bool {
        return [MNBootState.shutDown, .shuttingDown].contains(self.bootState)
    }
    
    // Any state other than running:
    var isUnavailable : Bool {
        return self.bootState != .running
    }
    
    var isNeedsSaving: Bool {
        get {
            bootStater.isNeedsSaving
        }
        set {
            if newValue != bootStater.isNeedsSaving {
                bootStater.isNeedsSaving = newValue
            }
        }
    }
}

private class MNBootableMgr {
    // MARK: properties
    var registry : [TypeDescriptor:[String:MNBootState]] = [:]
    
    // MARK: Singleton
    public static let shared = MNBootableMgr()
    private init(){
        
    }
    
    private func idName(for ided : any Identifiable)->String {
        var result = "\(ided.id)" // worst case
        // TODO: Consider which is better ??
        // When ided is AnyObject we can use
        // result = "id.mem\(String(memoryAddressOf: ided))"
        
        // Using id descriptions
        if let id = ided.id as? CustomStringConvertible {
            result = id.description
        } else if let id = ided.id as? LosslessStringConvertible {
            result = id.description
        } else {
            // No description to the id:
            result = "id.hash\(ided.id.hashValue)"
        }
        dlog?.verbose("idName for \(type(of: ided)) = \(result)")
        return result
    }
    
    private func composedKey(forTypeStr typeStr: String, idStr : String)->String {
        return "\(typeStr).\(idStr)"
    }
    
    private func key(for bootable : any MNBootable)->String {
        var key = String(memoryAddressOf: bootable)
        if let ided = bootable as? any Identifiable {
            key = idName(for: ided)
        }
        return composedKey(forTypeStr: "\(type(of:bootable))", idStr: key)
    }
    
    private func debugValidateRegistry(item : any MNBootable) {
        guard MNUtils.debug.IS_DEBUG else {
            return
        }
        
        // Validate
        let type = type(of: item)
        let typeKey = TypeDescriptor(type: type)
        var typedItems = registry[typeKey] ?? [:]
        let key = self.key(for: item)
        let registeredState = typedItems[key]
        
        if registeredState != item.bootState {
            dlog?.warning("debugValidateRegistry: State of MNBootable (\(key) is not the same as in the registry..")
        }
    }
    
    @discardableResult
    func updateState(of bootable : any MNBootable)->Bool {
        let type = type(of: bootable)
        let typeKey = TypeDescriptor(type: type)
        var typedItems = registry[typeKey] ?? [:]
        let instanceKey = self.key(for: bootable)
        if typedItems[instanceKey] !=  bootable.bootState {
            typedItems[instanceKey] = bootable.bootState
            registry[typeKey] = typedItems
            return true // Was updated
        }
        
        return false // Was not updated
    }
    
    
    /// Return the boot state for any registered item, or nil
    /// - Parameter item: item to get its state
    /// - Returns: boot state of the item, or nil if the item was not registered yet
    func getState(of item : Any)->MNBootState? {
        let typeName = "\(type(of:item))"
        if let item = item as? any MNBootable {
            self.debugValidateRegistry(item: item)
            return item.bootState
        } else if let item = item as? any Identifiable {
            let idName = self.idName(for: item)
            let typeKey = TypeDescriptor(type: type(of: item))
            if let typedItems = registry[typeKey] {
                let instanceKey = self.composedKey(forTypeStr: typeName, idStr: idName)
                return typedItems[instanceKey]
            }
        } else {
            dlog?.note("Item \(typeName) : \(item) was not found in the registry!")
        }
        
        return nil
    }
    
    
    /// Will return the boot state for a random registered item in the registry: this is good for singletone or other items where we are certain either only one instance exists, or items that have the same boot state at the same time (for all instances of this type.
    /// - Parameter type: type of item
    /// - Returns: boot state of a randome item of this type, or nil if no items for this type were registered
    func getState(forAnyInType type:Any.Type)->MNBootState? {
        let typeKey = TypeDescriptor(type: type)
        let typedItems = registry[typeKey] ?? [:]
        return typedItems.values.first
    }
    
    func getState(forAnyInTypeStr typeStr:String)->MNBootState? {
        guard let foundKey = registry.keys.first(where: { typeDesc in
            typeDesc.name == typeStr ||
            "\(typeDesc.type)" == typeStr
        }) else {
            return nil
        }
                
        return getState(forAnyInType: foundKey.type)
    }
}
