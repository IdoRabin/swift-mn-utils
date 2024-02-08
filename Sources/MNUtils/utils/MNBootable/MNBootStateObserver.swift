//
//  MNBootStateObserver.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNBootStateObserver") // ?.setting(verbose: true)

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
    func needsSaving<App:AnyObject>(object:ObjectType, inApp:App?) {}
    func willSave<App:AnyObject>(object:ObjectType, inApp:App?) {}
    func didSave<App:AnyObject>(object:ObjectType, inApp:App?) {}
    
    func willLoad<App:AnyObject>(object:ObjectType, inApp:App?) {}
    func didLoad<App:AnyObject>(object:ObjectType, inApp:App?) {}
}
