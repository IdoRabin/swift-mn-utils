//
//  File.swift
//  
//
//  Created by Ido on 19/08/2023.
//

import Foundation
import DSLogger

#if canImport(Vapor)
import Vapor
#endif

#if canImport(NIO)
import NIO
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("MNExec")?.setting(verbose: true)

#if canImport(NIO)
fileprivate extension NIODeadline /* delayFromNow : TimeInterval */ {
    static func delayFromNow(_ delay : TimeInterval)->NIODeadline {
        return NIODeadline.now() + .milliseconds(Int64(delay*1000))
    }
}
#endif

public class MNExec {
    
    public typealias CancelKey = String
    struct DateCKeyTuple : Hashable {
        let date : Date
        let cKey : CancelKey
    }
    #if canImport(Vapor)
    weak static var eventLoopGroup : EventLoopGroup!
    #endif
    
    #if canImport(Vapor)
    public static func setup(application:Vapor.Application) {
        eventLoopGroup = application.eventLoopGroup
    }
    #else
    public static func setup() {
    }
    #endif
    
    @discardableResult
    // @preconcurrency
    private static func internal_exec(afterDelay delay:TimeInterval, forcedCKey:CancelKey? = nil, block:@escaping ()->Void)->CancelKey? {
        guard delay >= 0 else {
            dlog?.note("exec(afterDelay:) delay should be a positive or zero value. (not \(delay))")
            return nil
        }
        let cKey : CancelKey = forcedCKey ?? Date.now.timeIntervalSince1970.description.toBase64()
        
        #if canImport(Vapor)
            dlog?.todo("MNExec.exec(afterDelay:\(delay)) in Vapor SHOULD VALIDATE IMPLEMENTATION")
            self.eventLoopGroup.next().scheduleTask(deadline: NIODeadline.delayFromNow(delay), block)
        #else
            DispatchQueue.main.asyncAfter(delayFromNow: delay) {[block] in // , dlog
                block()
            }
        #endif
        
        return cKey
    }
    
    /// Execute the block of code after the given delay (timing accuracy may vary)
    /// - Parameters:
    ///   - delay: delay before executing the block
    ///   - block: block to be executed
    /// - Returns: a cancel key to allow canceling the whole operation
    // @preconcurrency
    @discardableResult
    public static func exec(afterDelay delay:TimeInterval, block:@escaping ()->Void)->CancelKey? {
        return self.internal_exec(afterDelay: delay, block: block)
    }
    
    private static let debounceCache = MNCache<String, DateCKeyTuple>(name:"debounceCache", maxSize: 500)
    /// Will wait until the first time the delay has been waited and the function was not called for the key. At that time, will perform only the LAST block submitted.
    /// - Parameters:
    ///   - key: a unique key to identify the "location" in code where debounce is needed
    ///   - delay: delay time in seconds until the block will be performed
    ///   - block: block to be performed. Only the last block called before the timeout will be executed. the rest of the blocks will be released with no use!
    /// - Returns: a cancel key to allow canceling the whole operation
    @discardableResult
    public static func debounceExecutingLastBlockOnly(withKey key:String, afterDelay delay:TimeInterval, block:@escaping ()->Void)->CancelKey? {
        guard delay > 0 else {
            dlog?.info(">>> debounceExecLastBlockOnly delay should be a positive value. (not \(delay))")
            return nil
        }
        let now = Date.now
        let cKey : CancelKey = now.timeIntervalSince1970.description.toBase64()
        let prev = debounceCache[key]
        let tuple = prev ?? DateCKeyTuple(date: now, cKey: cKey)
        let delta = abs(tuple.date.timeIntervalSince(now))
        
        if delta < delay {
            // Time has not passed yet: we push the time forward and set new timeout:
            /*
            if let prev = prev {
                dlog?.verbose(">>> Time has not passed yet: pushing prev: \(prev.date.description)")
            } else {
                dlog?.verbose(">>> Time has not passed yet: pushing new: \(now.description)")
            }*/
            
            debounceCache[key] = tuple
            internal_exec(afterDelay: delay, forcedCKey: cKey, block: {[key, cKey] in
                if debounceCache[key]?.cKey == cKey {
                    block()
                } /*else {
                    dlog?.verbose(log: .fail, ">>> Canceled block")
                }*/
            })
            return cKey
        } else {
            // Time has already passed:
            dlog?.verbose(">>> Time has passed.")
            block()
            debounceCache[key] = nil
            return nil
        }
    }
    
    private static func internal_waitFor(_ key:String, test:@escaping ()->Bool, interval:TimeInterval, timeout:TimeInterval, block:@escaping (_ waitResult:WaitResult)->Void, startTime:Date, depth:Int)->CancelKey? {
        
        guard timeout > 0 && interval > 0 else {
            dlog?.note("waitFor(...interval:timeout:...) needs both interval and timeout to be > 0. interval needs to be smaller than timeout.")
            return nil
        }
        
        guard interval < timeout else {
            dlog?.note("waitFor(...interval:timeout:...) needs both interval and timeout to be > 0. interval needs to be smaller than timeout.")
            return nil
        }
        
        let current = abs(Double(depth) * interval)
        let expected = timeout + (2.0 * interval)
        guard (depth < 3000) || (current < expected) else {
            dlog?.warning("waitFor exceeded recursion depth \(depth) or exceeded the timeout \(timeout) by a big margin!")
            return nil
        }
                                 
        if interval > timeout * 0.49 {
            dlog?.note("waitFor(...interval:timeout:...) has an interval of \(interval) of timeout \(timeout) which means it will only be calld once!")
        }
        
        if test() {
            if MNUtils.debug.IS_DEBUG {
                if depth == 0 {
                    dlog?.verbose(log: .info , "waitFor: \(key) #\(depth) DONE Immediate (.success)")
                } else {
                    dlog?.verbose(log: .info , "waitFor: \(key) #\(depth) DONE (.success)")
                }
            }
            block(.success)
        } else if abs(startTime.timeIntervalSinceNow) >= timeout {
            // Call teh execution block immediately - we either timed out or result is a success
            dlog?.verbose(log: .info , "waitFor: \(key) #\(depth) DONE (.timeout)")
            block(.timeout)
        } else {
            // Timeout has not arrived yet:
            dlog?.verbose(log: .success , "waitFor: \(key) #\(depth)")
            self.internal_exec(afterDelay: interval, forcedCKey: key) {
                _ = self.internal_waitFor(key, test:test, interval: interval, timeout: timeout, block: block, startTime: startTime, depth: depth + 1)
            }
        }
        
        return nil
    }
    
    @discardableResult
    /// Will wait for a condition to evaluate to true or for the timeout to run our and call the execution block
    /// - Parameters:
    ///   - test: expression returning bool, when it evaluates to true, the execution block will be called
    ///   - interval: interval for testing the test block (must be smaller than timeout, and bigger than 0.0
    ///   - timeout: timeout after which (if the test block never returned true) the execution block will be called
    ///   - block: block to execute only if test evaluated true or timeout was called
    /// - Returns: a cancel key to allow canceling the whole operation
    public static func waitFor(_ key:String, test:@escaping ()->Bool, interval:TimeInterval, timeout:TimeInterval, block:@escaping (_ waitResult:WaitResult)->Void)->CancelKey? {
        internal_waitFor(key, test:test, interval: interval, timeout: timeout, block: block, startTime:Date.now, depth: 0)
    }
    
    public static var isMain : Bool {
        var result = false
        #if canImport(Vapor)
            dlog?.warning("TODO: implement MNExec.isMain ")
        #else
            result = DispatchQueue.isMainQueue
        #endif
        return result
    }
}
