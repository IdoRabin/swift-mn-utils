//
//  TimedEventFilter.swift
import Foundation
import Logging

public typealias TimedEventBlock = ()->Void
public typealias EventValues = (time:Date, contents:TimedEventBlock?)

fileprivate let dlog : Logger? = nil // Logger(label: "TimedEventFilter")

/// Filter incoming event so that even if the event is fired multiple times in short time interval, the event will be passes on according to a minimum time threshold between events.
/// Example: Even if "saveToDisk" is called 10 times in one second, only the last call will trigger the save to disk, thus limiting the overhead I/O of 10 saves just because of repeated events.
public final class TimedEventFilter {
    
    public static let DEFAULT_INTERVAL_FOR_TEXTFIELD : TimeInterval = 0.188
    
    private var _lock = NSRecursiveLock()
    private var _queue = DispatchQueue(label: "TimedEventFilter")
    private var _eventByKey : [String:EventValues] = [:]
    private var _accumValuesByKey : [String:[Any]] = [:]
    
    // MARK: Singleton
    public static let shared = TimedEventFilter()
    private init() {
        
    }
    
    
    // MARK: Private
    /// Get event by key in a thread safe manner
    ///
    /// - Parameter key: any event uniquely identifying key
    /// - Returns: event values for the given event key/
    private func safeEventByKey(_ key:String)->EventValues? {
        var result : EventValues? = nil
        _queue.safeSync {
            self._lock.lock {
                result = self._eventByKey[key]
            }
            
        }
        return result
    }
    
    private func safeAccumValsByKey(_ key:String)->[Any]? {
        var result : [Any]? = nil
        _queue.safeSync {
            self._lock.lock {
                result = self._accumValuesByKey[key]
            }
        }
        return result
    }
    
    private func safeLock(_ block : @escaping (_ aself: TimedEventFilter)->Void) {
        _queue.safeSync {[self] in
            self._lock.lock {[self] in
                block(self)
            }
        }
    }
    
    // Will filter events for the public methods by time -
    private func internal_FilterEvent(key:String, threshold:TimeInterval, willSkip: /*@escaping*/ TimedEventBlock? = nil, completion: @escaping TimedEventBlock) {
        guard threshold > 0.0 else {
            NSLog("⚠️ WARNING: TimedEventFilter filterEvent threshold is <= 0.0")
            return
        }
        guard key.count > 0 else {
            NSLog("⚠️ WARNING: TimedEventFilter filterEvent key is empty")
            return
        }

        // TODO: create dispatchQueue by key?
        DispatchQueue.notMainIfNeeded {
            var interval : TimeInterval = (0.01 * threshold)
            if let evt = self.safeEventByKey(key) {
                interval = fabs(evt.time.timeIntervalSinceNow)
                dlog?.info("internal_FilterEvent [\(key)] last event time: \(interval)")
            }
            
            if interval > threshold {
                
                // The event was called when enough time has passed since last call, so we execute it immediately:
                // Perform event now
                DispatchQueue.mainIfNeeded {
                    dlog?.info("internal_FilterEvent [\(key)] completion time: (\(interval))")
                    completion()
                }
                
                // Save last event time, but not the completion, which was called
                let time:Date = Date()
                self.safeLock { aself in
                    aself._eventByKey[key] = EventValues(time:time, contents:nil)
                }
                
                self._queue.asyncAfter(delayFromNow: threshold) {
                    
                    // After timeout, remove last event
                    if let evt = self.safeEventByKey(key), evt.time == time {
                        self.safeLock { aself in
                            aself._eventByKey[key] = nil
                        }
                    }
                }
            } else {
                
                // The event was called when NOT enough time has passed since last call, so we wait until later to execute
                // dlog?.info("event [\(key)] will skip")
                willSkip?()
                
                // Save event completion for later
                let time : Date = Date()
                self.safeLock { aself in
                    aself._eventByKey[key] = EventValues(time:time, contents:completion)
                }
                
                // Dispatch after threshold time
                self._queue.asyncAfter(delayFromNow: threshold) {
                    // dlog?.info("asyncAfter done for : [\(key)] interval: \(abs(time.timeIntervalSinceNow))")
                    
                    if let evt = self.safeEventByKey(key), evt.time.timeIntervalSince1970Int64 == time.timeIntervalSince1970Int64 {
                        
                        self.safeLock { aself in
                            aself._eventByKey[key] = EventValues(time:Date(), contents:nil)
                        }
                        
                        // last event was the event we are talking about, was not overrriden by newerr event
                        if let contents = evt.contents {
                            DispatchQueue.main.safeSync {
                                dlog?.info("event [\(key)] will call the event block -")
                                contents()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Public
    
    // Will call event immediately, but if was called recently, will wait until end of threashold ot call the event.
    /// Filter event by a uniquely identifying key so that a completion block will be called only if the time interval since last time the event was called is larger than the threashold, or the event has never been called. If the
    /// NOTE: after the "last" event in a burst is called, will wait threashold time and than call the last events' completion
    ///
    /// - Parameters:
    ///   - key: uniquely identifying key for an event that is called rapidly
    ///   - threshold: time threashold between event completions. The rest of the completions will be ignored and not called
    ///   - completion: completion block to perform when the time interval between events is big enough / on first call
    public func filterEvent(key:String, threshold:TimeInterval, completion: @escaping TimedEventBlock) {
        internal_FilterEvent(key: key, threshold: threshold, completion: completion)
    }
    
    
    /// Will call event immediately, but if was called recently, will wait until end of threashold ot call the event.
    /// Filter event by a uniquely identifying key so that a completion block will be called only if the time interval since last time the event was called is larger than the threashold, or the event has never been called. If the
    /// NOTE: after the "last" event in a burst is called, will wait threashold time and than call the last events' completion
    ///
    /// - Parameters:
    ///   - key: uniquely identifying key for an event that is called rapidly
    ///   - threshold: time threashold between event completions. The rest of the completions will be ignored and not called
    ///   - accumArray: will accumulate an array of all elementes/ objects in all the arrays added before the completion block is performed. Will add only uniquely new items (union)
    ///   - completion: completion block to perform when the time interval between events is big enough / on first call. contains an array of all accumulated items
    public func filterEvent<T:Equatable>(key:String, threshold:TimeInterval, accumArray:[T], completion: @escaping ([T]?)->Void) {
        
        @discardableResult func accum(t:[T])->[T] {
            var result : [T] = t
            
            self.safeLock { [key] aself in
                let vals = (aself.safeAccumValsByKey(key) as? [T]) ?? [] // get existing array or create a new empty one
                result = vals.union(with: t) // union old with new array - uniqueElements kept..
                aself._accumValuesByKey[key] = result
            }
            
            return result
        }
        
        self.internal_FilterEvent(key: key, threshold: threshold) {
            
            // Skipped - completion was not called yet
            // dlog?.info("internal_FilterEvent key: .\(key) Skipped....")
            accum(t: accumArray)
            
        } completion: {
            // Completed
            // dlog?.info("internal_FilterEvent key: .\(key) Completion....")
            let sumArr = accum(t: accumArray)
            
            DispatchQueue.main.safeSync {
                completion(sumArr)
            }
            
            // Aftr we call
            self._queue.asyncAfter(delayFromNow: threshold * 1.1) {[self, key] in
                self.safeLock { [key] aself in
                    self._accumValuesByKey[key] = nil
                }
            }
        }

    }
    
    public func filterEvent<T:Equatable>(key:String, threshold:TimeInterval, accumulating:T, completion: @escaping ([T]?)->Void) {
        self.filterEvent(key: key, threshold: threshold, accumArray: [accumulating], completion: completion)
    }
    
}
