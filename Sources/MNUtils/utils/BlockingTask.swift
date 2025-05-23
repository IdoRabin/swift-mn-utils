//
//  BlockingTask.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging

fileprivate let dlog : Logger? = Logger(label: "BlockingTask") // ?.setting(verbose: false)

//@frozen
public final class BlockingTask<Success, Failure> where Success : Sendable, Failure : Error {

    private(set) public var result : MNResult<Success> = .failure(code: .misc_unknown, reason: "<?>")
    
    @discardableResult
    public init(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success) {
        let twlock = Thread.current.isMainThread ? nil : MNThreadWaitLock()
        if MNUtils.debug.IS_DEBUG && twlock == nil {
            dlog?.notice("BlockingTask was called onMainThread. Will not block! \(String(describing: operation))->\(Success.self)")
        }
        // We block this thred/loop until the Task asyncs are done:
        Task<Success, Error>.detached(priority:priority, operation: {[self] in
            do {
                let res = try await operation()
                self.result = .success(res)
            } catch let error {
                self.result = .failure(fromError: error)
                throw error
            }
            twlock?.signal()
            switch result {
            case .failure(let error):
                throw error
            case .success(let succ):
                return succ
            }
        })
        
        twlock?.waitForSignal()
    }
    
}
