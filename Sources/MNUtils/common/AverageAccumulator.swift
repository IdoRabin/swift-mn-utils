//
//  AverageAccumulator.swift
//  expenser
//
//  Created by Ido on 20/08/2019.
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("AverageAccumulator")

public class AverageAccumulator : Codable {
    
    fileprivate struct AccumTuple : CustomStringConvertible, Codable, Hashable {
        let amount: Int
        let value : Double
        var description: String {
            return "<AccumTuple val:\(value) amt:\(amount) avg:\(self.average)>"
        }
        
        var average : Double {
            guard self.amount > 0 else {
                return 0
            }
            
            return self.value / Double(self.amount)
        }
    }
    
    fileprivate class Payload : Codable {
        fileprivate(set) var tuples : [AccumTuple] = []
        fileprivate(set) var name : String = ""
        fileprivate(set) var isLog : Bool = false
        
        /// This allows for keeping a rolling average and or minimizing size of data, popping the oldest values, and keeping the newest
        /// When amount of measurements exceeds this property - will be popping firsts upon inserting lasts. (by calling the "add" functions)
        fileprivate(set) var maxSize : Int = 0
        
        static var empty : Payload {
            return Payload()
        }
    }
    
//    @SkipEncode
//    @SkipEncode
//    @SkipEncode
//    @SkipEncode
    
    private var payload = Payload()
    private var _lock = NSRecursiveLock()
    private var _isPersistentInFile : Bool = false
    private var _isNeedsSave : Bool = false
    private var _lastSaveTime : Date? = nil
    
    public var isNeedsSave : Bool {
        return _isNeedsSave
    }

    public init(named:String, persistentInFile:Bool = false, maxSize:Int = 2048) {
        self.payload.name = named
        self.payload.maxSize = maxSize
        self._isPersistentInFile = persistentInFile
        if self._isPersistentInFile {
            _ = self.load()
            self.payload.maxSize = maxSize // set again after load
        }
    }
    
    func log(_ string:String) {
        if payload.isLog && MNUtils.debug.IS_DEBUG {
            dlog?.info("[\(payload.name)] \(string)")
        }
    }
    
    var count : Int {
        get {
            var result = 0
            self._lock.lock {
                result = self.payload.tuples.count
            }
            return result
        }
    }
    
    private var isSaveNeeded : Bool {
        return self._isPersistentInFile && self._isNeedsSave
    }
    
    public var valuesTotalSum : Double {
        var sum : Double = 0.0
        self._lock.lock {
            for tuple in payload.tuples {
                sum += tuple.value
            }
        }
        return sum
    }
    
    public var amountsTotalSum : Int {
        var count = 0
        self._lock.lock {
            for tuple in payload.tuples {
                count += tuple.amount
            }
        }
        return count
    }
    
    public var intAverage : Int {
        return Int(round(self.average))
    }
    
    public var mean : Double {
        guard self.count > 0 else {
            return 0.0
        }
        
        var sorted : [AccumTuple] = []
        self._lock.lock {
            sorted = self.payload.tuples.sorted { (t1, t2) -> Bool in
                return t1.average > t2.average
            }
        }
        
        let mid = Int(ceil(Double(sorted.count) / 2.0))
        if sorted.count % 2 == 0 {
            return (sorted[mid].average + sorted[mid - 1].average) / 2.0
            
        } else {
            return sorted[mid].average
        }
    }
    
    public var average : Double {
        guard self.count > 0 else {
            return 0.0
        }
        var sum = Double(self.amountsTotalSum)
        if sum == 0 {
            sum = 0.000000001 // prevent divide by zero
        }
        return Double(self.valuesTotalSum) / sum
    }
    
    public func rollingAverage(forLast:Int)->Double {
        guard self.count > 0 else {
            return 0.0
        }
        
        var count : Double = 0.0
        var sum : Double = 0.0
        self._lock.lock {
            for tuple in payload.tuples {
                count += Double(tuple.amount)
                sum += tuple.value
            }
        }
        
        if count == 0 {
            count = 0.000000001 // prevent divide by zero
        }
        return Double(sum) / count
    }
    
    public var entriesCount : Int {
        return self.count
    }
    
    public func popIfNeeded() {
        if self.payload.maxSize > 0 && self.count > self.payload.maxSize {
            let delta = self.count - self.payload.maxSize
            self.removeFirst(delta)
        }
    }
    
    public func add(amount: Int, value : Double) {
        self._lock.lock {
            self.payload.tuples.append(AccumTuple(amount: amount, value: value))
            self._isNeedsSave = true
            self.popIfNeeded()
        }
    }
    
    public func add(amount: Int, value : Int) {
        self._lock.lock {
            self.payload.tuples.append(AccumTuple(amount: amount, value: Double(value)))
            self._isNeedsSave = true
            self.popIfNeeded()
        }
    }
    
    public func add(amount: Int, value : CGFloat) {
        self._lock.lock {
            self.payload.tuples.append(AccumTuple(amount: amount, value: Double(value)))
            self._isNeedsSave = true
            self.popIfNeeded()
        }
    }
    
    public func add(amount: Int, value : Float) {
        self._lock.lock {
            self.payload.tuples.append(AccumTuple(amount: amount, value: Double(value)))
            self._isNeedsSave = true
            self.popIfNeeded()
        }
    }
    
    public func values()->[Double] {
        var result : [Double] = []
        self._lock.lock {
            result = self.payload.tuples.map { (tuple) -> Double in
                return tuple.value
            }
        }
        
        return result
    }
    
    public func amounts()->[Int] {
        var result : [Int] = []
        
        self._lock.lock {
            result = self.payload.tuples.map { (tuple) -> Int in
                return tuple.amount
            }
        }
        
        return result
    }
    
    public func remove(where test:(Int,Double)->Bool) {
        var indexes : [Int] = []
        
        self._lock.lock {
            self.payload.tuples.forEachIndex { (index, tuple) in
                if test(tuple.amount, tuple.value) {
                    // Will remove from last to first, hence, no need to keep track which index was removed
                    indexes.insert(index, at: 0)
                    self._isNeedsSave = true
                }
            }
            
            // Indexes are sorted from last to first in indexes array
            for index in indexes {
                self.payload.tuples.remove(at: index)
                self._isNeedsSave = true
            }
        }
    }
    
    public func removeLast(_ amount : Int = 1) {
        if entriesCount > amount {
            self._lock.lock {
                self.payload.tuples.removeLast(amount)
                self._isNeedsSave = true
            }
        }
    }
    
    public func removeFirst(_ amount : Int = 1) {
        if entriesCount > amount {
            self._lock.lock {
                self.payload.tuples.removeFirst(amount)
                self._isNeedsSave = true
            }
        }
    }
    
    public func clear() {
        payload.tuples.removeAll()
        self.save()
    }
    
    public func sort() {
        
        // Will sort all tuples by their average value
        self._lock.lock {
            self.payload.tuples.sort { (t1, t2) -> Bool in
                return t1.average > t2.average
            }
            self._isNeedsSave = true
        }
    }
    
    // MARK: Codable
    enum CodingKeys : CodingKey {
        case payload
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.payload = try container.decodeIfPresent(Payload.self, forKey: .payload) ?? Payload.empty
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payload, forKey: .payload)
    }
}

/* saving of cache as a whole */
public extension AverageAccumulator /* saving */ {
    
    func filePath(forKeys:Bool)->URL? {
        // .libraryDirectory -- not accessible to user by Files app
        // .cachesDirectory -- not accessible to user by Files app, for caches and temps
        // .documentDirectory -- accessible to user by Files app
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fname = self.payload.name.replacingOccurrences(of: CharacterSet.whitespaces, with: "_").replacingOccurrences(of: CharacterSet.punctuationCharacters, with: "_")
        
        url?.appendPathComponent("mnaverages")
        
        if (!FileManager.default.fileExists(atPath: url!.path)) {
            do {
                try FileManager.default.createDirectory(atPath: url!.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                dlog?.warning("filePath creating subfolder \(url?.lastPathComponent ?? "<nil>" ) failed. error:\(error.description)")
            }
        }
        
        if forKeys {
            url?.appendPathComponent("kays_for_\(fname).json")
        } else {
            url?.appendPathComponent("\(fname).json")
        }
        
        return url!
    }
    
    @discardableResult
    func saveIfNeeded()->Bool {
        let interval = abs(self._lastSaveTime?.timeIntervalSinceNow ?? 0)
        if self._isNeedsSave && (interval == 0) || (interval > 1.0 /* second */) {
            return self.save()
        }
        return false
    }
    
    @discardableResult
    func save()->Bool{
        if let url = self.filePath(forKeys: false) {
            do {
                
                let saveItem = self.payload
                
                let encoder = MNJSONEncoder()
                let data = try encoder.encode(saveItem)
                    
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                dlog?.info("save [\(self.payload.name)] size: \(data.count) bytes, \(self.payload.tuples.count) items filename: \(url.lastPathComponents(count: 3))")
                self._lastSaveTime = Date()
                self._isNeedsSave = false
                return true
            } catch {
                dlog?.raisePreconditionFailure("save [\(self.payload.name)] failed with error:\(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    @discardableResult
    func load()->Bool {
        if let url = self.filePath(forKeys: false), FileManager.default.fileExists(atPath: url.path) {
            let displayPath = url.lastPathComponents(count: 3)
            
            if let data = FileManager.default.contents(atPath: url.path) {
                do {
                    let decoder = JSONDecoder()
                    let saved : Payload = try decoder.decode(Payload.self, from: data)
                    if self.payload.name == saved.name {
                        self._lock.lock {
                            // NO NEED self.name = saved.name
                            self.payload.tuples = saved.tuples
                            
                            if self.payload.isLog != saved.isLog {
                                self.payload.isLog = saved.isLog
                                dlog?.info("load() changed isLog:\(self.payload.isLog)")
                            }
                        }
                        return true
                    } else {
                        dlog?.note("load() failed casting dictionary filename:\(displayPath)")
                    }
                } catch {
                    dlog?.warning("load() failed with error:\(error.localizedDescription)")
                }
            } else {
                dlog?.warning("load() no data at \(displayPath)")
            }
        } else {
            dlog?.warning("load() no file at \(self.filePath(forKeys: false)?.path ?? "<nil>" )")
        }
        
        return false
    }
}
