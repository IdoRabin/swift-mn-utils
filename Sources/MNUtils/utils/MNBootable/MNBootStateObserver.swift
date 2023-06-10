//
//  MNBootStateObserver.swift
//  
//
//  Created by Ido on 10/06/2023.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNBootStateObserver")?.setting(verbose: true)

typealias AppInstanceType = AnyObject
public protocol MNBootStateObserver<ObjectType> {
    associatedtype ObjectType
    
    func willBoot<App:AnyObject>(object:ObjectType, inApp:App?)
    func didBoot<App:AnyObject>(object:ObjectType, inApp:App?)
    
    func needsSaving<App:AnyObject>(object:ObjectType, inApp:App?)
    func willSave<App:AnyObject>(object:ObjectType, inApp:App?)
    func didSave<App:AnyObject>(object:ObjectType, inApp:App?)
    
    func willLoad<App:AnyObject>(object:ObjectType, inApp:App?)
    func didLoad<App:AnyObject>(object:ObjectType, inApp:App?)
    
    func willShutdown<App:AnyObject>(object:ObjectType, inApp:App?)
    func didShutdown<App:AnyObject>(object:ObjectType, inApp:App?)
    
}

public extension MNBootStateObserver /* default implementation */ {
    // ?
}
