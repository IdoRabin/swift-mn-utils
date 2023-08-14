//
//  Cache.swift
//
//  Created by Ido on 04/02/2021.
//  Copyright © 2022 . All rights reserved.
//

import Foundation
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("Cache")

// typealias CodableHashable = Codable & Hashable
// typealias AnyCodable = Any & Codable
// typealias AnyEquatable = Any & Equatable
// typealias AnyCodableEquatable = Any & Codable & Equatable
// typealias AnyCodableHashable = Any & Codable & Hashable

public enum MNCacheErrorCode : Int, Codable, Equatable, JSONSerializable {
    case unknown = 9000
    case failed_loading = 9001 // equals AppErrorCodes and MNErrorCodes
    case misc_failed_encoding = 9031
    case misc_failed_decoding = 9032
}

public struct MNCacheError : Error, Codable, Equatable, JSONSerializable { // AppErrorable
    var desc: String
    var domain: String
    var code: Int
    var reason: String
    
    init(code:MNCacheErrorCode, reason:String, cacheName:String) {
        self.code = code.rawValue
        self.domain = "com.bricks.CacheError[\(cacheName)]"
        self.reason = reason
        self.desc = "\(code)"
    }
}

public protocol MNCodingKeyable {
    static func codingKeyType()-> CodingKey.Protocol
    func codingKeyType()-> CodingKey.Protocol
}

// MARK: Cache observer protocol - called when a cache changes
public protocol MNCacheObserver : AnyObject {
    
    
    // MARK: CacheObserver Optionals
    /// Notification when an item in the cache has beein updated / added
    /// - Parameters:
    ///   - uniqueCacheName: unique name of the cache
    ///   - key: cahing key for the given item
    ///   - value: item that was updated / added
    func cacheItemUpdated(uniqueCacheName:String, key:Any, value:Any)
    
    
    /// Updated a dictionary of items in one go
    func cacheItemsUpdated(uniqueCacheName:String, updatedItems:[AnyHashable:Any])
    
    /// Notification when the whole cache was cleared
    /// - Parameter uniqueCacheName: unique name of the cache
    func cacheWasCleared(uniqueCacheName:String)
    func cacheItemsWereRemoved(uniqueCacheName:String, keys:[Any])
    
    // MARK: CacheObserver Required
    func cacheWasLoaded(uniqueCacheName:String, keysCount:Int, error:MNCacheError?)
}

public extension MNCacheObserver /* optionals */ {
    func cacheItemUpdated(uniqueCacheName:String, key:Any, value:Any) { }
    
    
    /// Updated a dictionary of items in one go
    func cacheItemsUpdated(uniqueCacheName:String, updatedItems:[AnyHashable:Any]) { }
    
    /// Notification when the whole cache was cleared
    /// - Parameter uniqueCacheName: unique name of the cache
    func cacheWasCleared(uniqueCacheName:String) { }
    func cacheItemsWereRemoved(uniqueCacheName:String, keys:[Any]) { }
    
}

// TODO: Check if can be Actor
// MARK: Cache decleration
public typealias AnyCache = MNCache<AnyHashable, AnyHashable>
public class MNCache<Key : Hashable, Value : Hashable> {
    
    var defaultSearchPathDirectory : FileManager.SearchPathDirectory {
        return .cachesDirectory
    }
    
    /// Strategy / policy of attempting to load the last saved files for the cache:
    public enum CacheLoadType {
        /// Do not attempt to load on init
        case none
        
        /// attempt to load on init, immediately from the init call (blocking)
        case immediate
        
        /// attempt to load after init, on the next runloop run from after init call (does not block)
        case nextRunloop
    }
    
    /// Strategy / policy of attempting to load the last saved files for the cache:
    public enum MNCacheLoadPolicy {
        
        /// Load and when done, delete all existing key/values, and swt nly the loaded ones
        case replaceAll
        
        /// Load and when done, add / replace the loaded ones with all the existing key/values. (keys that exist for other reasons in the cache and were not loaded will remain in the cache)
        case merge
        
        /// Load, log how many were loaded, and then dump loaded items and clear the cache completely
        case debugLoadAndClear
    }
    
    public struct ValueInfo : Hashable {
        let value:Value
        let date:Date?
    }
    
    private var _lock = NSRecursiveLock()
    private var _maxSize : UInt = 10
    private var _flushToSize : UInt? = nil
    private var _items : [Key:ValueInfo] = [:]
    private var _latestKeys : [Key] = []
    private var _lastSaveTime : Date? = nil
    private var _isNeedsSave : Bool = false
    private var _isMemoryCacheOnly : Bool = false
    private var _oldestItemsDates : [Date] = []
    private var _isFlushItemsOlderThan : TimeInterval? = Date.SECONDS_IN_A_MONTH
    private var _searchPathDir : FileManager.SearchPathDirectory? = nil
    private var _saveFolder : String? = nil
    private var _isSavesDates : Bool = false
    private var _isSavesTypes : Bool = false
    private var _loadError : MNCacheError? = nil
    private (set) var isLoaded : Bool = false {
        didSet {
            if isLoaded == true, oldValue != isLoaded {
                notifyWasLoaded(error: self._loadError)
                self._loadError = nil
            }
        }
    }
    var loadPolicy : MNCacheLoadPolicy = .replaceAll
    public var whenLoaded : [(MNCacheError?)->Void] = [] {
        didSet {
            if self.isLoaded {
                Task {
                    notifyWhenLoaded(clearAllBlocks:true, error:self._loadError)
                }
            }
        }
    }
    
    var determinePolicyAfterLoad : ((_ existing:[Key])->MNCacheLoadPolicy)? = nil {
        didSet {
            let isNil = self.determinePolicyAfterLoad == nil
            let wasNil = oldValue == nil
            if !isNil && !wasNil {
                if self.isLoaded {
                    dlog?.note(".determinePolicyAfterLoad was set to a block, but the cache [\(self.name)] has already finished loading.")
                }
            }
        }
    }
    
    // const
    private let _maxOldestDates : UInt = 200
    
    public var name : String = ""
    public var isLog : Bool = false
    public var observers = ObserversArray<MNCacheObserver>()
    
    // Overrides the default loading mechanism to allow custom load element
    public typealias CacheDecodeJSONFragmentBlock =  (_ key:String,_ val:Any)->(items:[Key:Value], date:Date)
    public var decodeElementFromJSONFragment : CacheDecodeJSONFragmentBlock? = nil
    
    /// For cases of non-homogenous caches / of Value and Value subclasses.
    /// Requires also an override for creating all the instances from json using the lambda
    public var isSavesTypes : Bool {
        get {
            return _isSavesTypes
        }
        set {
            if newValue != _isSavesTypes {
                _isSavesTypes = newValue
                self.flushToDatesIfNeeded()
                self.isNeedsSave = true
            }
        }
    }
    
    // When loading objects by their type when using the loadWithSubTypes function, will fail or throw errors during load
    public var isDecodingSubTypeItemFailsOnNilReasult : Bool = true
    
    public var isSavesDates : Bool {
        get {
            return _isSavesDates
        }
        set {
            if newValue != _isSavesDates {
                _isSavesDates = newValue
                self.flushToDatesIfNeeded()
                self.isNeedsSave = true
            }
        }
    }
    
    /// Will flush items older than TimeInterval (in miliseconds, so 1000 is one second!)
    public var isFlushItemsOlderThan : TimeInterval? {
        get {
            return _isFlushItemsOlderThan
        }
        set {
            if newValue != _isFlushItemsOlderThan {
                _isFlushItemsOlderThan = newValue
                self.flushToDatesIfNeeded()
                self.isNeedsSave = true
            }
        }
    }
    
    // MARK: Functions
    func notifyWhenLoaded(clearAllBlocks:Bool, error:MNCacheError?) {
        for block in whenLoaded {
            block(error)
        }
        // Clear after calling all
        if clearAllBlocks {
            whenLoaded.removeAll()
        }
    }
    
    func notifyWasLoaded(error:MNCacheError?) {
        // Call wasLoaded on observers and whenLoaded blocks
        self.observers.enumerateOnCurrentThread { observer in
            observer.cacheWasLoaded(uniqueCacheName: self.name, keysCount: self.keys.count, error: error)
        }
        
        // Call completion blocks...
        self.notifyWhenLoaded(clearAllBlocks: true, error: error)
    }
    
    func log(_ args:CVarArg...) {
        if isLog && MNUtils.debug.IS_DEBUG {
            if args.count == 1 {
                dlog?.info("\(self.logPrefix)\(args.first!)")
            } else {
                dlog?.info("\(self.logPrefix)\(args)")
            }
        }
    }
    
    func logWarning(_ args:CVarArg...) {
        let alog = dlog ?? DLog.misc[self.logPrefix]
                
        if args.count == 1 {
            alog?.warning("\(self.logPrefix)\(args.first!)")
        } else {
            alog?.warning("\(self.logPrefix)\(args)")
        }
    }
    
    func logNote(_ args:CVarArg...) {
        if args.count == 1 {
            dlog?.note("\(self.logPrefix)\(args.first!)")
        } else {
            dlog?.note("\(self.logPrefix)\(args)")
        }
    }
    
    fileprivate var logPrefix : String {
        return /* DLog key: "Cache" */ "[\(name)]";
    }
    
    public var maxSize : UInt {
        get {
            return _maxSize
        }
        set {
            if maxSize != newValue {
                self._maxSize = newValue
                if let flushToSize = self._flushToSize {
                    self._flushToSize = min(flushToSize, max(self.maxSize - 1, 0))
                }
                self.flushIfNeeded()
            }
        }
    }
    
    public var count : Int {
        get {
            var result = 0
            self._lock.lock {
                result = self._items.count
            }
            return result
        }
    }
    
    public var isMemoryCacheOnly : Bool {
        get {
            return _isMemoryCacheOnly
        }
        set {
            _isMemoryCacheOnly = newValue
        }
    }
    
    public var isNeedsSave : Bool {
        get {
            return _isNeedsSave
        }
        set {
            if _isNeedsSave != newValue {
                _isNeedsSave = newValue
                if newValue {
                    self.needsSaveWasSetEvent()
                }
            }
        }
    }
    
    public var lastSaveTime : Date? {
        get {
            return _lastSaveTime
        }
        set {
            if _lastSaveTime != newValue {
                _lastSaveTime = newValue
                if let date = _lastSaveTime, MNUtils.debug.IS_DEBUG {
                    let interval = fabs(date.timeIntervalSinceNow)
                    switch interval {
                    case 0.0..<0.1:
                        self.logWarning("\(self.logPrefix) was saved multiple times in the last 0.1 sec.")
                    case 0.1..<0.2:
                        self.logNote("\(self.logPrefix) was saved multiple times in the last 0.2 sec.")
                    case 0.2..<0.99:
                        self.logNote("\(self.logPrefix) was saved multiple times in the last 1.0 sec.")
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// Initialize a Cache of elements with given kes and values with a unique name, max size and flusToSize
    /// - Parameters:
    ///   - name: unique name - this will be used for loggin and saving / loading to files. Use one unique name for each cached file. Having two instances at the same time with the same unique name may create issues. Having two instanced with the same unique name but other types for keys anfd values will for sure create undefined crashes and clashes.
    ///   - maxSize: maximum size for the cache (amount of items). Beyond this size, oldest entered items will be popped, and newwest pushed into the cache.
    ///   - flushToSize: nil or some value. When nil, the cache will pop as many items as required to remain at the maxSize level. When defined, once the caceh hits or surpasses maxSize capaity, te cache will flust and keep only the latest flushToSize elements, popping the remaining elements. flushToSize must be smaller than maxSize by at least one.
    public init(name:String, maxSize:UInt, flushToSize:UInt? = 0) {
        self.name = name
        self._maxSize = max(maxSize, 1)
        if let flushToSize = flushToSize {
            self._flushToSize = min(max(flushToSize, 0), self._maxSize)
        }
        MNCachesHelper.shared.observers.add(observer: self)
    }
    
    deinit {
        observers.clear()
        MNCachesHelper.shared.observers.remove(observer: self)
    }
    
    fileprivate func needsSaveWasSetEvent() {
        // Override point
    }
    
    private func validate() {
        self._lock.lock {
            // Debug validations
            for key in self._latestKeys {
                if self._items[key] == nil {
                    self.logWarning("\(self.logPrefix) flushed (cur count: \(self._items.count)) but no item found for \(key)")
                }
            }
            for (key, _) in self._items {
                if !_latestKeys.contains(key) {
                    self.logWarning("\(self.logPrefix) flushed (cur count: \(self._items.count)) but key \(key) is missing in latest")
                }
            }
            
            if _items.count != self._latestKeys.count {
                self.logWarning("\(self.logPrefix) flushed (cur count: \(self._items.count)) and some items / keys are missing")
            }
        }
    }
    
    fileprivate func flushToSizesIfNeeded() {
        self._lock.lock {
            if self._latestKeys.count > maxSize {
                let overhead = self._latestKeys.count - Int(self._flushToSize ?? self.maxSize)
                if overhead > 0 {
                    let keys = Array(self._latestKeys.prefix(overhead))
                    let dates = self._items.compactMap { (info) -> Date? in
                        return info.value.date
                    }
                    self._items.remove(valuesForKeys: keys)
                    
                    let remainingKeys = Array(self._items.keys)
                    self._latestKeys.remove { (key) -> Bool in
                        !remainingKeys.contains(key)
                    }

                    // NOTE: We are assuming only one item has this exact date,
                    self._oldestItemsDates.remove(objects: dates)
                    
                    if MNUtils.debug.IS_DEBUG {
                        self.validate()
                    }
                    self.log("Flushed to size \(_latestKeys.count) items:\(self._items.count)")
                    self.isNeedsSave = true
                    
                    // Notify observers
                    observers.enumerateOnMainThread { (observer) in
                        observer.cacheItemsWereRemoved(uniqueCacheName:self.name, keys: keys)
                    }
                }
            }
        }
    }
    
    fileprivate func flushToDatesIfNeeded() {
        guard self.isSavesDates else {
            return
        }
        
        guard self.isSavesDates else {
            return
        }
        
        guard let olderThanSeconds = self._isFlushItemsOlderThan else {
            return
        }
        
        // Will  not flush all the time
        TimedEventFilter.shared.filterEvent(key: "Cache_\(name)_flushToDatesIfNeeded", threshold: 0.2) {[self] in
            let clearedCount = self.clear(olderThan: olderThanSeconds)
            self.log("flushToDatesIfNeeded: cleared \(clearedCount) items older than: \(olderThanSeconds) sec. ago. \(self.count) remaining.")
        }
    }
    
    public func flushIfNeeded() {
        self.flushToSizesIfNeeded()
        self.flushToDatesIfNeeded()
    }
    
    public subscript (key:Key) -> Value? {
        get {
            return self.value(forKey: key)
        }
        set {
            if let value = newValue {
                self.add(key: key, value: value)
            } else {
                // newValue is nil
                self.remove(key:key)
            }
        }
    }
    
    public var keys : [Key] {
        get {
            var result : [Key] = []
            self._lock.lock {
                result = Array(self._items.keys)
            }
            return result
        }
    }
    
    private func addToOldestItemsDates(_ date:Date) {
        self._oldestItemsDates.append(date)
        if self._oldestItemsDates.count > self._maxOldestDates {
            self._oldestItemsDates.remove(at: 0)
        }
    }
    
    /// All cached values as array! NOTE: may be memory intensive!
    public var values : [Value] {
        get {
            var result : [Value] = []
            self._lock.lock {
                result = Array(self._items.values).map({ (info) -> Value in
                    return info.value
                })
            }
            return result
        }
    }
    
    /// Gets all values with the given keys
    /// - Parameter keys: all keys to search with. Optional, defaults to nil. When nil, will return ALL ITEMS!!
    /// NOTE: May be memory intensive!
    /// - Returns: dictionary of all found values by their keys
    public func values(forKeys keys:[Key]? = nil)->[Key:Value] {
        guard let keys = keys else {
            // All keys
            return self.values(forKeys: self.keys)
        }
        guard keys.count > 0 else {
            return [:]
        }
        return asDictionary(forKeys: keys)
    }
    
    public func values(where test:(Key, Value)->Bool)->[Value] {
        return self.asDictionary(where: test).valuesArray
    }
    
    public func asDictionary(where test:(Key, Value)->Bool)->[Key:Value] {
        var result : [Key:Value] = [:]
        self._lock.lock {
            for key in self._items.keysArray {
                // Exists and passes test:
                if let val = self._items[key]?.value,
                    test(key, val) == true {
                    
                    // Add to result
                    result[key] = val
                }
            }
        }
        
        return result
    }
    
    public func asDictionary(forKeys keys:[Key]? = nil)->[Key:Value] {
        var result : [Key:Value] = [:]
        self._lock.lock {
            let keyz = keys ?? self._items.keysArray
            for key in keyz {
                if let val = self._items[key]?.value {
                    result[key] = val
                }
            }
        }
        
        return result
    }
    
    public func value(forKey key:Key)->Value? {
        return self.asDictionary(forKeys: [key]).values.first
    }
    
    public func hasValue(forKey key:Key)->Bool {
        return self.value(forKey: key) != nil
    }
    
    public func remove(key:Key) {
        var wasRemoved = false
        self._lock.lock {
            wasRemoved = (self._items[key] != nil) // existed to begin with
            
            if let date = self._items[key]?.date {
                // NOTE: We are assuming only one item has this exact date,
                self._oldestItemsDates.remove(elementsEqualTo: date)
            }
            
            self._items[key] = nil
            self._latestKeys.remove(elementsEqualTo: key)
            self.log("Removed \(key). count: \(self.count)")
        }
        
        // Notify observers
        if wasRemoved {
            self.isNeedsSave = true
            observers.enumerateOnMainThread { (observer) in
                observer.cacheItemsWereRemoved(uniqueCacheName:self.name, keys: [key])
            }
        }
    }
    
    public func add(dictionary:[Key:Value]) {
        self._lock.lock {
            self.flushIfNeeded()
            let date = self.isSavesDates ? Date() : nil
            for (key, value) in dictionary {
                self._items[key] = ValueInfo(value:value, date:date)
            }
        }
        
        // Notify observers
        observers.enumerateOnMainThread { (observer) in
            observer.cacheItemsUpdated(uniqueCacheName: self.name, updatedItems: dictionary)
        }
    }
    
    public func add(key:Key, value:Value) {
        self._lock.lock {
            self.flushIfNeeded()
            let date = self.isSavesDates ? Date() : nil
            self._items[key] = ValueInfo(value:value, date:date)
            
            // mutating - remove all prev references to key (lifo)
            self._latestKeys.remove(elementsEqualTo: key)
            
            // mutating - insert on top the new key
            self._latestKeys.append(key)
            // self.log(" Added | \(key) | count: \(self.count)")
            self.isNeedsSave = true
        }
        
        // Notify observers
        observers.enumerateOnMainThread { (observer) in
            observer.cacheItemUpdated(uniqueCacheName:self.name, key: key, value: value)
        }
    }
    
    public func clearMemory(but exceptKeys: [Key]? = nil) {
        self._lock.lock {
            if exceptKeys?.count ?? 0 == 0 {
                self._items.removeAll()
                self._latestKeys.removeAll()
                self.log(" Memory Cleared all. count: \(self.count)")
            } else if let exceptKeys = exceptKeys {
                self._items.removeAll(but:exceptKeys)
                self._latestKeys.remove { (key) -> Bool in
                    return exceptKeys.contains(key)
                }
                self.log("Memory Cleared all but: \(exceptKeys.count) keys. count: \(self.count)")
            }
        }
    }
    
    public func clearForMemoryWarning() throws {
        dlog?.info("\(self.logPrefix) clearForMemoryWarning 1") // will always log when in debug mode
        self.clearMemory()
    }
    
    
    /// Will clear all elements in the array
    /// - Parameter exceptKeys: but / except keys - a list of specific keys to NOT clear from the cache - that is, keep in the cache after the "clear".
    public func clear(but exceptKeys: [Key]? = nil) {
        self._lock.lock {
            self.clearMemory(but: exceptKeys)
            self.isNeedsSave = true
        }
        
        // Notify observers
        observers.enumerateOnMainThread { (observer) in
            observer.cacheWasCleared(uniqueCacheName: self.name)
        }
    }
    
    /// Will clear and flush out of the cache all items whose addition date is older than a given cutoff date. Items exatly equal to the cutoff date remain in the cache.
    /// - Parameter cutoffDate: date to compare items to
    /// - Returns: number of items removed from the cache
    @discardableResult
    public func clear(beforeDate cutoffDate: Date)->Int {
        guard self.isSavesDates else {
            self.logNote("clear beforeDate cannot clear when cache [\(self.name)] isSaveDates == false")
            return 0
        }
        
        var cnt = 0
        let newItems = self._items.compactMapValues { (info) -> ValueInfo? in
            if let date = info.date {
                if date.isLaterOrEqual(otherDate: cutoffDate) {
                    return info
                }
            }
            cnt += 1
            return nil
        }
        
        if MNUtils.debug.IS_DEBUG {
            if cnt != self._items.count - newItems.count {
                self.logNote("clear beforeDate validation of items removed did not come out right!")
            }
        }
        
        // Save
        if cnt > 0 {
            self._items = newItems
            self.isNeedsSave = true
        }
        
        return cnt
    }
    
    /// Will clear all items older than this amount of seconds out of the cache
    /// - Parameter olderThan: seconds of "age" - items that were added to the cache more than this amount of seconds agor will be removed out of the cache
    @discardableResult
    public func clear(olderThan: TimeInterval)->Int {
        guard self.isSavesDates else {
            self.logNote("clear olderThan cannot clear when cache [\(self.name)] isSaveDates == false")
            return 0
        }
        let date = Date(timeIntervalSinceNow: -olderThan)
        return self.clear(beforeDate: date)
    }
}

extension MNCache : MNCachesEventObserver {
    public func applicationDidReceiveMemoryWarning(_ application: Any) {
        do {
            try self.clearForMemoryWarning();
        }
        catch (let error) {
            self.logWarning("\(logPrefix) applicationDidReceiveMemoryWarning: error: \(error.description)")
        }
    }
}

public extension MNCache where Key : CodableHashable /* saving of keys only*/ {
    
    func filePath(forKeys:Bool)->URL? {
        var url : URL? = nil
        if let path = self._saveFolder {
            url = URL(fileURLWithPath: path)
            if url == nil {
                dlog?.warning("\(self.logPrefix) filePath(forKeys:) failed with savePath: \(path): invalid URL! failed fileURLWithPath!")
                return nil
            }
        } else {
            // .libraryDirectory -- not accessible to user by Files app
            // .cachesDirectory -- not accessible to user by Files app, for caches and temps
            // .documentDirectory -- accessible to user by Files app
            // .autosavedInformationDirectory --
            url = FileManager.default.urls(for: self._searchPathDir ?? self.defaultSearchPathDirectory, in: .userDomainMask).first
        }
        
        let fname = self.name.replacingOccurrences(of: CharacterSet.whitespaces, with: "_").replacingOccurrences(of: CharacterSet.punctuationCharacters, with: "_")
        url?.appendPathComponent("mncaches")
        
        let path = url!.path
        if (!FileManager.default.fileExists(atPath: path)) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                self.logWarning("filePath creating subfolder \(url?.lastPathComponent ?? "<nil>" ) failed. error:\(error)")
            }
        }
        
        if forKeys {
            url?.appendPathComponent("kays_for_\(fname).json")
        } else {
            url?.appendPathComponent("\(fname).json")
        }
        
        return url!
    }
    
    func saveKeysIfNeeded()->Bool {
        let interval = abs(self._lastSaveTime?.timeIntervalSinceNow ?? 0)
        if self.isNeedsSave && (interval == 0) || (interval > 1.0 /* second */) {
            var result : Bool = true
            do {
                result = try self.saveKeys();
            } catch let error {
                self.logWarning("saveKeysIfNeeded failed on saveKeys: \(error.description)")
                result = false
            }
            return result
        }
        return false
    }
    
    func saveKeys() throws->Bool{
        
        guard self._isMemoryCacheOnly == false else {
            self._lastSaveTime = Date()
            self.isNeedsSave = false
            return true
        }
        
        if let url = self.filePath(forKeys: true) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self.keys)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                self._lastSaveTime = Date()
                self.isNeedsSave = false
                self.log("saveKeys size:  \(data.count) filename: \(url.path)")
                
                return true
            } catch {
                // May re-throw
                dlog?.raisePreconditionFailure("\(self.logPrefix) saveKeys Cache [\(self.name)] failed with error:\(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    func loadKeys()->[Key]? {
        if let url = self.filePath(forKeys: true), FileManager.default.fileExists(atPath: url.path) {
            if let data = FileManager.default.contents(atPath: url.path) {
                let decoder = JSONDecoder()
                do {
                    // dlog?.info("loadKeys [\(self.name)] load data size:\(data.count)")
                    let loadedKeys : [Key] = try decoder.decode([Key].self, from: data)
                    self.log("loadKeys [\(self.name)] \(loadedKeys.count ) keys")
                    return loadedKeys
                } catch {
                    self.logWarning("loadKeys [\(self.name)] failed with error:\(error.localizedDescription)")
                }
            } else {
                self.logWarning("loadKeys [\(self.name)] no data at \(url.path)")
            }
        } else {
            self.logWarning("loadKeys [\(self.name)] no file at \(self.filePath(forKeys: true)?.path ?? "<nil>" )")
        }
        
        return nil
    }
    
    func clearForMemoryWarning() throws {
        dlog?.info("\(self.logPrefix) clearForMemoryWarning 2") //
        _ = try saveKeys()
        self.clearMemory()
    }
}

/* saving of cache as a whole */
fileprivate let moduleName = String(String(reflecting: StringAnyDictionary.self).prefix { $0 != "." })
public extension MNCache where Key : CodableHashable, Value : Codable {
    
    private func initLoadIfNeeded(attemptLoad:CacheLoadType){
        switch attemptLoad {
        case .immediate:
            _ = self.load()
        case .nextRunloop:
            Task {
                _ = self.load()
            }
        case .none:
            self.isLoaded = true
            fallthrough
        default:
            break
        }
    }
    
    /// Initialize a Cache of elements with given kes and values with a unique name, max size and flusToSize
    /// - Parameters:
    ///   - name: unique name - this will be used for loggin and saving / loading to files. Use one unique name for each cached file. Having two instances at the same time with the same unique name may create issues. Having two instanced with the same unique name but other types for keys anfd values will for sure create undefined crashes and clashes.
    ///   - maxSize: maximum size for the cache (amount of items). Beyond this size, oldest entered items will be popped, and newwest pushed into the cache.
    ///   - flushToSize: nil or some value. When nil, the cache will pop as many items as required to remain at the maxSize level. When defined, once the caceh hits or surpasses maxSize capaity, te cache will flust and keep only the latest flushToSize elements, popping the remaining elements. flushToSize must be smaller than maxSize by at least one.
    ///   - attemptLoad: will attempt loading this cache immediately after init from the cache file, saved previously using saveIfNeeded(), save(), or by AutoSavedCache class.
    convenience init(name:String, maxSize:UInt, flushToSize:UInt? = 0, attemptLoad:CacheLoadType, searchDirectory:FileManager.SearchPathDirectory? = nil) {
        self.init(name: name, maxSize: maxSize, flushToSize: flushToSize)
        self._searchPathDir = searchDirectory
        self.initLoadIfNeeded(attemptLoad: attemptLoad)
    }
    
    convenience init(name:String, maxSize:UInt, flushToSize:UInt? = 0, attemptLoad:CacheLoadType, saveFolder:String) {
        self.init(name: name, maxSize: maxSize, flushToSize: flushToSize)
        self._searchPathDir = nil
        self._saveFolder = saveFolder.removingPercentEncodingEx // Prevents  creating Applicatioh%20Support
        self.initLoadIfNeeded(attemptLoad:attemptLoad)
    }
    
    struct SavableValueInfo : CodableHashable {
        let value:Value
        let date:Date?
        let type:String?
    }
    
    fileprivate struct SavableStruct : Codable {
        var saveTimeout : TimeInterval = 0.3
        var maxSize : UInt = 10
        var flushToSize : UInt? = nil
        var items : [Key:SavableValueInfo] = [:]
        var latestKeys : [Key] = []
        var name : String = ""
        var isLog : Bool = false
        var oldestItemsDates : [Date] = []
        var isSavesDates : Bool = true
        var isSavesTypes : Bool = false
        var isFlushItemsOlderThan : TimeInterval? = nil
        
    }
    
    private func itemsToSavableItems()-> [Key:SavableValueInfo] {
        var savableItems : [Key:SavableValueInfo] = [:]
        for (key, info) in self._items {
            savableItems[key] = SavableValueInfo(value:info.value,
                                                 date:info.date,
                                                 type: self.isSavesTypes ? "\(type(of:info.value))" : nil)
        }
        return savableItems
    }
    
    func savableItemsToItems(_ savalbelInput: [Key:SavableValueInfo])->[Key:ValueInfo] {
        var items : [Key:ValueInfo] = [:]
        for (key, info) in savalbelInput {
            items[key] = ValueInfo(value:info.value, date:info.date)
        }
        return items
    }
    
    fileprivate func createSavableStruct()->SavableStruct {
        // Overridable
        let saveItem = SavableStruct(maxSize: _maxSize,
                                     flushToSize: _flushToSize,
                                     items: self.itemsToSavableItems(),
                                     latestKeys: _latestKeys,
                                     name: self.name,
                                     isLog: self.isLog,
                                     oldestItemsDates: self._oldestItemsDates,
                                     isSavesDates: self.isSavesDates,
                                     isSavesTypes: self.isSavesTypes,
                                     isFlushItemsOlderThan: self._isFlushItemsOlderThan)
        return saveItem
    }
    
    @discardableResult func saveIfNeeded()->Bool {
        let interval = abs(self._lastSaveTime?.timeIntervalSinceNow ?? 0)
        if self.isNeedsSave && (interval == 0) || (interval > 1.0 /* second */) {
            return self.save()
        }
        return false
    }
    
    @discardableResult func save()->Bool{
        
        guard self._isMemoryCacheOnly == false else {
            self._lastSaveTime = Date()
            self.isNeedsSave = false
            return true
        }
        
        if let url = self.filePath(forKeys: false) {
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch let err {
                self.logNote(".save() - failed removing file: \(err.localizedDescription) path:\(url.path)")
            }
            
            do {
                let saveItem = self.createSavableStruct()
                
                let encoder = JSONEncoder()
                let data = try encoder.encode(saveItem)
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                self.log(".save() size: \(data.count) filename: \(url.lastPathComponents(count: 3))")
                self._lastSaveTime = Date()
                self.isNeedsSave = false
                return true
            } catch {
                dlog?.raisePreconditionFailure("Cache[\(self.name)].save() failed with error:\(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    private func determineVTypeAndVTypeStr(valBeingDecoded val:Any)->(valueType:Value.Type, typeStr:String)? {
        // Determine type:
        var resType : Value.Type = Value.self
        var typeStr : String = "\(Value.self)"
        
        // Saved types:
        if self.isSavesTypes, let dict = val as? StringAnyDictionary {
            
            // We redefine type tp what actually is written in the type k/v pair:
            if let atypeStr = dict["type"] as? String { typeStr = atypeStr }
            
            // Try to get class from string:
            if let classN = Bundle.main.classNamed(typeStr) {
                // SubType What is our value's Type using the ["type"] key in the root of the dict:
                if let subType = classN as? Value.Type {
                    resType = subType
                    // log(" Found SAVED type for element! \(subType) elem:\(val)")
                }
            }
        }
        
        if self.isSavesTypes, let atypeStr = (val as? [String:Any])?["type"] as? String {
            
            // Value to decode is [String:Any] dictionary:
            typeStr = atypeStr
            if let classN = Bundle.main.classNamed(typeStr) {
                // SubType What is our value's Type using the ["type"] key in the root of the dict:
                if let subType = classN as? Value.Type {
                    resType = subType
                    // log(" Found SAVED type for element! \(subType) elem:\(val)")
                }
            } else {
                if let resFound = StringAnyDictionary.getType(typeName: typeStr) {
                    if let atype = resFound.type as? Value.Type {
                        // log(" Found SAVED type for element! \(resFound) className: \(typeStr)")
                        resType = atype
                        typeStr = "\(resFound.name).\(resType)"
                    } else {
                        logWarning(" UnkeyedEncodingContainerEx Failed: Found class / type [\(resType.self)] canot be cast to [\(Value.self)]")
                    }
                } else {
                    logWarning(" Failed to get class / type for type string: [\(typeStr)]. Use StringAnyDictionary.registerClass(class) to allow easy decoding UnkeyedEncodingContainerEx")
                }
            }
        }
        
        // Result:
        return (valueType:resType, typeStr:typeStr)
    }
    
    
    /// Loads the data from the saved version when expecting items in the cache to not be homogeneous, but rather all descendants of the generic Value type.
    /// - Parameter data: data to parse when loading
    /// - Returns: array of [Key:ValueInfo] to be set into the cache upon its init.
    private func loadWithSubTypes(data:Data) ->[Key:ValueInfo] {
        if MNUtils.debug.IS_DEBUG { self.isLog = true }
        
        var result : [Key:ValueInfo] = [:]
        
        if MNUtils.debug.IS_DEBUG && self._isSavesDates {
            self.logWarning(".loadWithSubTypes TODO: IMPLEMENT load dates from value for loadWithSubTypes!")
        }
        var pairsExpected = 0
        var pairsParsed = 0
        
        // decode a single pair:
        func decodePair(key:String, val:Any) {
            
            // If we have a ready function to decode each value:
            if let decodeBlock = self.decodeElementFromJSONFragment {
                // var decodeElementFromJSONFragment : (([String:Any])->[Key:Value])? = nil
                // Decodes using the set property lambda / block:
                let decodedTuple = decodeBlock(key, val)/* -> returns dict of [Key:Value] */
                for (akey, item) in decodedTuple.items {
                    let valueInfo = ValueInfo(value: item, date: decodedTuple.date)
                    pairsParsed += 1
                    result[akey] = valueInfo
                }
            } else if let types = self.determineVTypeAndVTypeStr(valBeingDecoded: val) {
                
                
                // dlog?.info("Decoding val: [+] for \(types.valueType) \(types.typeStr)")
                if let val = val as? StringAnyDictionary, let valueDic = val["value"] as? StringAnyDictionary {
                    // Approaches to decode:
                    if let ResultType = types.valueType as? StringAnyInitable.Type {
                        
                        // Decode subtype with dict
                        if let instance = ResultType.createInstance(stringAnyDict: valueDic) as? Value {
                            
                            if Key.self != String.self {
                                DLog.warning("[TODO] : loadWithSubTypes(data:Data) needs a keyForValue function external? lambda? block?")
                            }
                            
                            if let resultkey = key as? Key {
                                let valueInfo = ValueInfo(value: instance, date: self.isSavesDates ? Date.now : nil)
                                result[resultkey] = valueInfo
                                pairsParsed += 1
                            } else {
                                logNote(".loadWithSubTypes Failed finding key or value for StringAnyDictionary as sub-value")
                            }
                        } else if self.isDecodingSubTypeItemFailsOnNilReasult {
                            logNote(".loadWithSubTypes Failed init for \(types.valueType).init(stringAnyDict:) for content: \(val["value"].descOrNil) returned nil")
                        }
                    }
                } else {
                    logNote(".loadWithSubTypes cannot parse sub types when input is not [String:Any] dictionary: \(val)")
                }
            }
        }

        // Decode all and iterate for saved pairs in dictionary:
        do {
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let dict = dict, let items = dict["items"] as? [String: Any] {
                pairsExpected = items.count
                for key in items.sortedKeys {
                    let itemToParse = items[key]!
                    // call Nested func:
                    decodePair(key:key, val:itemToParse)
                }
                // log("✓ loadWithSubTypes \(items.sortedKeys.descriptionsJoined)") // checkmark ✓
                if self.isDecodingSubTypeItemFailsOnNilReasult && pairsExpected > 0 && pairsExpected > pairsParsed {
                    throw MNCacheError(code:.misc_failed_decoding,
                                       reason: "Cache<\(self.name)> failed decoding all \(pairsExpected) expected items",
                                       cacheName: self.name)
                }
            } else {
                logNote(".loadWithSubTypes elements not found!")
            }
        } catch let error {
            logWarning(".loadWithSubTypes \(error.description)")
        }
        
        return result
    }
    
    func load()->Bool {
        var loadErr : MNCacheError? = nil
        
        // Try to load from file:
        let url = self.filePath(forKeys: false)
        if let url = url, FileManager.default.fileExists(atPath: url.path) {
            if let data = FileManager.default.contents(atPath: url.path) {
                do {
                    let decoder = JSONDecoder()
                    decoder.setUserInfo("Cache.Load<\(Key.self),\(Value.self)>", forKey: "load_context_str")
                    let saved : SavableStruct = try decoder.decode(SavableStruct.self, from: data)
                    let dataCnt = data.count
                    
                    if self.name == saved.name {
                        self._lock.lock {
                            // NO NEED to assign: self.name = saved.name
                            func setItems(_ newDict : [Key:ValueInfo]) {
                                switch self.loadPolicy {
                                case .merge:
                                    self._items.merge(dict: newDict)
                                case .debugLoadAndClear:
                                    if MNUtils.debug.IS_DEBUG {
                                        logNote(" Cache.Load<\(Key.self),\(Value.self)> has .debugLoadAndClear!")
                                        self.clear()
                                    } else {
                                        logWarning("Cache.Load<\(Key.self),\(Value.self)> has .debugLoadAndClear policy, but build is NOT in debug mode!")
                                        fallthrough
                                    }
                                case .replaceAll:
                                    if newDict.count == 0 && self.count > 0 && dataCnt > 10 {
                                        logWarning("Cache.Load<\(Key.self),\(Value.self)>loaded 0 ITEMS! Loaded data size: \(dataCnt) from: \(url.path)")
                                    }
                                    self._items = newDict
                                
                                } // end switch
                            } // end func setItems
                            
                            // Some flags must load first:
                            self._isSavesTypes = saved.isSavesTypes
                            
                            if self.isSavesTypes || self.decodeElementFromJSONFragment != nil {
                                let result = self.loadWithSubTypes(data: data)
                                if dlog?.isVerboseActive == true {
                                    self.log(".loadWithSubTypes / custom decoding: \(result.count) items loaded (will replace \(self._items.count) items)")
                                }
                                setItems(result)
                            } else {
                                // Load by regular JSON Decoder
                                setItems(self.savableItemsToItems(saved.items))
                            }
                            self._latestKeys = saved.latestKeys
                            
                            // Check for maxSize chage:
                            if self.maxSize != saved.maxSize {
                                self.maxSize = saved.maxSize
                                self.log(".load() maxSize value has changed: \(self.maxSize)")
                            }
                            
                            // Check for _flushToSize chage:
                            if self._flushToSize != saved.flushToSize {
                                self._flushToSize = saved.flushToSize
                                self.log(".load() flushToSize value has changed: \(self._flushToSize?.description ?? "<nil>" ) flushToSize)")
                            }
                            
                            // Check for isLog chage:
                            if self.isLog != saved.isLog {
                                self.isLog = saved.isLog
                                self.log(".load() isLog value has changed: \(self.isLog)")
                            }
                            
                            
                            self._oldestItemsDates = saved.oldestItemsDates
                            self._isSavesDates = saved.isSavesDates
                            self._isFlushItemsOlderThan = saved.isFlushItemsOlderThan
                            
                            // Time has passed when we were saved - we can clear the cache now
                            self.flushToDatesIfNeeded()
                        }
                        
                        self.isLoaded = true
                        return true
                    } else {
                        loadErr = MNCacheError(code: .failed_loading, reason: "failed loading: failed casting dictionary ", cacheName: self.name)
                        self.logWarning(".load() failed casting dictionary filename:\(url.lastPathComponents(count: 3))")
                    }
                } catch {
                    loadErr = MNCacheError(code: .failed_loading, reason: "failed loading: underlying error:\(String(describing: error))", cacheName: self.name)
                    self.logWarning(".load() failed with error:\(String(describing: error))")
                }
            } else {
                loadErr = MNCacheError(code: .failed_loading, reason: "failed loading: no data in file: \(url.absoluteString)", cacheName: self.name)
                self.logWarning(".load() no data at \(url.lastPathComponents(count: 3))")
            }
        } else {
            loadErr = MNCacheError(code: .failed_loading, reason: "failed loading: no file at: \(url?.absoluteString ?? "<url is nil>")", cacheName: self.name)
            self.logWarning(".load() no file at \(self.filePath(forKeys: false)?.path ?? "<nil>" )")
        }
        
        
        self._loadError = loadErr
        self.isLoaded = true
        return false
    }
    
    func clearForMemoryWarning() throws {
        self.log("clearForMemoryWarning 3")
        _ = try saveKeys()
        self.clearMemory()
    }
}

/// Subclass of Cache<Key : Hashable, Value : Hashable> which attempts to save the cache frequently, but with a timed filter that prevents too many saves per given time
public class MNAutoSavedCache <Key : CodableHashable, Value : CodableHashable> : MNCache<Key, Value>  {
    private var _timeout : TimeInterval = 0.3
    
    override var defaultSearchPathDirectory : FileManager.SearchPathDirectory {
        return .autosavedInformationDirectory
    }
    
    /// Timeout of save event being called after changes are being made. default is 0.3
    public var autoSaveTimeout : TimeInterval {
        get {
            return _timeout
        }
        set {
            if newValue != _timeout {
                _timeout = max(newValue, 0.01)
            }
        }
    }
    
    override fileprivate func needsSaveWasSetEvent() {
        super.needsSaveWasSetEvent()
        
        TimedEventFilter.shared.filterEvent(key: "\(self.name)_AutoSavedCacheEvent", threshold: max(self.autoSaveTimeout, 0.03)) {
            self.flushToDatesIfNeeded()
            
            self.log("AutoSavedCache saveIfNeeded called")
            _ = self.saveIfNeeded()
        }
    }
}

public class DBCache <Key : CodableHashable, Value : CodableHashable> : MNAutoSavedCache <Key, Value> {
    // TODO: Implement?
    /*override*/ func save() -> Bool {
        dlog?.todo("\(self.logPrefix) implement DBCache.save()!")
        return false
    }
    
    /*override*/ func load() -> Bool {
        dlog?.todo("\(self.logPrefix) implement DBCache.load()!")
        return false
    }
}

