//
//  MNThreadWaitLock.swift
//  testVerbs
//
//  Created by Ido Rabin on 23/05/2017.
//  Copyright © 2022 Ido Rabin. All rights reserved.
//

import Foundation
#if VAPOR
import Vapor
#endif

/// Returns the current queue name, not exactly the current thread name, but the Queue
///
/// - Returns: string of the currect quque name
public func currentQueueName() -> String
{
    let name = __dispatch_queue_get_label(nil)
    if let str = String(cString: name, encoding: .utf8)
    {
        if (str == "com.apple.main-thread")
        {
            return "mainThread"
        }
        else if (str == "com.apple.root.default-qos")
        {
            return "defaultQueue"
        }
        return str
    }
    
    return "Unknown"
}

/// Wrapper to conditional lock to work with threads / dispatch queues
/// The main task of this lock is to safely block a thread and wait until a task is completed in another thread and then unblock and resume the original thread's operation.
///
/// This class cen be used in two main fashions:
///
/// **Manual usage:**
/// by allocating an instance and using only the `blockAndWait` and `unblockAndResume` methods in appropriate locations in the code, where `blockAndWait` will lock a thread until the lock is unlocked, and calling `unblockAndResume` to unlock the thread
///
/// ````
/// let lock = MNThreadWaitLock()
/// someDispacthQueue.async {
///    DispatchQueue.global().async {
///        // Perform tasks in this thread..
///        ...
///        // Implementers MUST call unblockAndResume, otherwise the thread will be blocked indefinetely
///        lock.signal()
///    }
///
///    // Will block this thread until the other queue calls unblockAndResume
///    lock.waitForSignal()
///    // Perform tasks after the other thread has completed
/// }
/// ````
///
/// **Automatic usage:**
/// by calling the asyncDispatch methods `asyncDispatchInGlobalQueue` or `asyncDispatch` etc. In this mode of operation, the function `blockAndWait` is called under the hood in the required queue and halts the execution until the blockInThread block calls `unblockAndResume`.
///
/// **NOTE:** implementers are *required* to call `unblockAndResume` in the blockInThread block, otherwise the lcok will be locked indefinetely / thread will be blocked indefinately
/// ````
/// let lock = MNThreadWaitLock()
/// lock.asyncDispatchInGlobalQueue(label: "myThreadNameAKAMyQueueLabel", blockInThread: { (lock) in
///    // Perform tasks in the thread..
///    ...
///    // Implementers MUST call unblockAndResume, otherwise the thread will be blocked indefinetely
///    lock.signal()
/// }) {
///    // Completion block will be called after the blockInThread has completed:
///    // Perform tasks after the dispatch thread has completed
/// }
/// ````
final public class MNThreadWaitLock
{
    // TODO: Test for multiple re-uses (lock, unlock and then again lock, unlock) of the same ThreadWaitLock instance
    static let WAIT_LOCK_IS_WORKING = 1
    static let WAIT_LOCK_IS_DONE = 2
    
    let lock :NSConditionLock
    
    public init()
    {
        lock = NSConditionLock(condition: MNThreadWaitLock.WAIT_LOCK_IS_WORKING)
    }

    /// `waitForSignal()` will lock a thread until `signal()` is called (which will 'unblock' the thread)
    public func waitForSignal() {
        // Wait for the result: (block this thread until delegate unlocks the conditional)
        lock.lock(whenCondition: MNThreadWaitLock.WAIT_LOCK_IS_DONE)
        lock.unlock(withCondition: MNThreadWaitLock.WAIT_LOCK_IS_DONE)
        lock.unlock(withCondition: MNThreadWaitLock.WAIT_LOCK_IS_WORKING) // Reset to starting state - this allows reuse of the same instance - lock again, and unlock again etc..
    }
    
    /// `signal()` should be called from within another thread than that in which `waitForSignal()` was called. When called, this will 'unblock' the thread in which `waitForSignal()` was called from.
    public func signal() {
        // Signals the generateAdViewWithContext: to unlock after completion
        if (lock.tryLock(whenCondition: MNThreadWaitLock.WAIT_LOCK_IS_WORKING)) {
            lock.unlock(withCondition: MNThreadWaitLock.WAIT_LOCK_IS_DONE)
        }
    }
    
    /// Will dispatch a work block in an async queue, block the queue until the `unblockAndResume` method is called inside the `blockInThread` block
    ///
    /// - Parameters:
    ///   - queue: a dispatch queue to perform the events in, and wait for `blockInThread` to call `unblockAndResume`
    ///   - label: a label to name the dispatch queue call with
    ///   - blockInThread: a completion block that is called upon. The queue waits for this block to call `unblockAndResume` before continuing
    ///   - completion: a completion block called after the quque is unblocked
    private func asyncDispatch(in queue:DispatchQueue?, label:String? = nil, blockInThread:@escaping(MNThreadWaitLock)->(),completion:@escaping ()->Void)
    {
        if let queueToUse = (queue == nil) ? DispatchQueue.global() : queue
        {
            queueToUse.async {
                if let threadLabel = label
                {
                    Thread.current.name = threadLabel
                }
                blockInThread(self)
                self.waitForSignal()
                completion()
            }
        }
    }
    
    
    /// Will dispatch a work block in the global queue as an async block, will block the queue until the `unblockAndResume` method is called inside the `blockInThread` block
    ///
    /// - Parameters:
    ///   - label: a label to name the dispatch queue call with
    ///   - blockInThread: a completion block that is called upon. The queue waits for this block to call `unblockAndResume` before continuing
    ///   - completion: a completion block called after the quque is unblocked
    func asyncDispatchInGlobalQueue(label:String? = nil, blockInThread:@escaping(MNThreadWaitLock)->(),completion:@escaping ()->Void)
    {
        self.asyncDispatch(in: nil, label: label, blockInThread: blockInThread, completion: completion)
    }
    
    func asyncDispatch(in queue:DispatchQueue?, blockInThread:@escaping(MNThreadWaitLock)->(),completion:@escaping ()->Void)
    {
        self.asyncDispatch(in: queue, label: nil, blockInThread: blockInThread, completion: completion)
    }
}
