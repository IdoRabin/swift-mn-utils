//
//  MNBootStateObserver.swift
//  
//
//  Created by Ido on 10/06/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNBootStateObserver")?.setting(verbose: true)

public protocol MNBootStateObserver<ObjectType> {
    associatedtype ObjectType
    
    func willBoot(object:ObjectType, inApp:AppType?)
    func didBoot(object:ObjectType, inApp:AppType?)
    
    func needsSaving(object:ObjectType, inApp:AppType?)
    func willSave(object:ObjectType, inApp:AppType?)
    func didSave(object:ObjectType, inApp:AppType?)
    
    func willLoad(object:ObjectType, inApp:AppType?)
    func didLoad(object:ObjectType, inApp:AppType?)
    
    func willShutdown(object:ObjectType, inApp:AppType?)
    func didShutdown(object:ObjectType, inApp:AppType?)
    
}

public extension MNBootStateObserver /* default implementation */ {
    // ?
}
