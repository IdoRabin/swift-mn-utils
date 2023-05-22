//
//  MNLogger.swift
//
//  Created by Ido Rabin for  on 30/10/2022.
//  Copyright © 2022 Ido Rabin. All rights reserved.
//

// ❌ ❗👁 ⚠️️ ▶ ✘ ✔

import Foundation

public typealias MNLogKeys = Array<String>
public typealias MNLogFilterSet = Set<String>
// TODO: Transition to MNLogFilter aet...

// TODO: Transition to MNLogItem
private struct MNLogItem {
    
    var granularity : MNLogGranularity = .default
    var level : MNLogLevel = .info
    let items : [String]
    
    private (set) var _output : MNLogOutput = []
    
    init(_ granulatiry:MNLogGranularity = .default, _ level:MNLogLevel = .info, items:String...) {
        self.init(granulatiry, level, items: items)
    }
    
    init(_ granulatiry:MNLogGranularity = .default, _ level:MNLogLevel = .info, items:[String]) {
        self.granularity = granulatiry
        self.level = level
        self.items = items
    }
    mutating func setOutput(_ output : MNLogOutput) {
        self._output = output
    }
    
    var asLogString : String? {
        var arr : [String] = []
        
        switch granularity {
        case .verbose:
            arr.append("▶ verbose")
            
        case .warningsOnly:
            // Verbose allowed only for warnings and notes
            if ![.warning, .note, .fail, .assertFailure, .raisePrecondition].contains(level) {
                return nil
            } else {
                arr.append("▶ warnings")
            }
        case .disabled:
            // arr.append("▶ disabled")
            return nil
        case .default:
            // No "granularity" prefix
            break
        }
        
        
        
        var mark = " "
        switch level {
        case .info: break; // adds nothing
        case .success: mark += "✔"
        case .fail: mark += "✘"
        case .note: mark += "⚠️️"
        case .warning: mark += "❗"
        case .todo: mark += "👁"
        case .raisePrecondition: mark += "❌"
        case .assertFailure: mark += "❌"
        }
        if mark.count > 0 {
            arr.append(mark)
        }
        let cleanedStr = arr.joined(separator: " ").replacingOccurrences(of: "  ", with: " ")
        let result = "\(cleanedStr) | \(items.description)"
        return result
    }
}

/// Logger class
public final class MNLogger {
    
    static let IS_LOGS = MNUtils.debug.IS_DEBUG
    
    // MARK: types
    public typealias Completion = (_ didOccur:Bool)->Void
    public typealias ExpectedItem = (string:String, step:Int, completion: Completion?)
    
    // MARK: Testing static members
    private static let MAX_CACHE_SIZE = 32
    private static let MAX_EXPECT_WAIT = 32
    private static var expectStepCounter : Int = 0
    private static var stringsToExpect: [ExpectedItem] = []
    private static var filterOut:MNLogFilterSet = [MNLogGranularity.verbose.rawValue] // When empty, all logs are output, otherwise, keys that are included are logged out
    private static var filterIn:MNLogFilterSet = [] // When empty, all logs are output, otherwise, keys that are included are the only ones output - this takes precedence over filterOut
    private static var alwaysPrinted:[MNLogLevel] = [.warning, .fail, .raisePrecondition, .note] // Will allow printing even when filtered out using filter
    
    // MARK: Private date stamp
    private static let dateFormatter = DateFormatter()
    private let keys:MNLogKeys
    private (set) var curGranularity : MNLogGranularity = .default
    
    // MARK: Private indent level
    private var _indentLevel : Int = 0
    fileprivate var indentLevel : Int {
        get {
            return _indentLevel
        }
        set {
            _indentLevel = min(max(newValue, 0), 16)
        }
    }
    
    
    
    // MARK: Testing
    init(keys:MNLogKeys) {
        MNLogger.dateFormatter.dateFormat = "HH:mm:ss.SSS"
        self.keys = keys.uniqueElements()
        self.setting(granularity: .default)
    }
    
    func isGranularityAllowed(_ grain: MNLogGranularity)->Bool {
        return grain <= self.curGranularity
    }
    
    /// A setter method to set the required granularity / verbosity level for this logger.
    /// NOTE: returns self to allow chaining - for example: init().setting(...) in a one-liner
    /// - Parameter granularity: level of granularity of this log (verbosity)
    /// - Returns: self instance for daisy chaining
    @discardableResult
    func setting(granularity:MNLogGranularity = .default)->MNLogger {
        
        self.curGranularity =  granularity
        
        // Daisy chaining..
        return self
    }
    
    @discardableResult
    func setting(verbose:Bool)->MNLogger {
        return self.setting(granularity: verbose ? .verbose : .default)
        
    }
    /// Add log (string) keys into the filter, only these keys will be logged from now on
    ///
    /// - Parameter keys: keys to filter (only these will be printed into log, unless in .alwaysPrinted array)
    public static func filterOnlyKeys(_ keys:MNLogKeys) {
        filterIn.formUnion(keys)
    }
    
    /// Remove log (string) keys from the filter, these keys will not be able to log from now on
    ///
    /// - Parameter keys: keys to unfilter (will note be printed into log)
    public static func unfilterOnlyKeys(_ keys:MNLogKeys) {
        filterIn.subtract(keys)
    }
    
    /// Add log (string) keys into the filter, these keys will not be logged from now on
    ///
    /// - Parameter keys: keys to filter (will not be printed into log, unless in .alwaysPrinted array
    public static func filterOutKeys(_ keys:MNLogKeys) {
        filterOut.formUnion(keys)
    }
    
    /// Remove log (string) keys from the filter, these keys will be able to log from now on
    ///
    /// - Parameter keys: keys to unfilter (will be printed into log)
    public static func unfilterOutKeys(_ keys:MNLogKeys) {
        filterOut.subtract(keys)
    }
    
    /// Supress log calls containing the given string for the near future log calls
    ///
    /// The function saves the string to expect for MAX_CACHE_SIZE_CALLS.
    /// The function is used to catch future logs
    /// If during these series of calls the string expected did occur, the logging will be surpressed (ignored)
    /// - Parameter containedString: the string for the logging mechanism to ignore in the next x expected log calls
    public func testingIgnore(containedString:String) {
        #if TESTING
            // Add new completion to see if it will be called in the future
            MNLogger.stringsToExpect.append((text: containedString, step:MNLogger.expectStepCounter, completion:nil))
            
            if (MNLogger.stringsToExpect.count > MNLogger.MAX_CACHE_SIZE) {
                // Pop oldest completion as failed
                let older = MNLogger.stringsToExpect.remove(at: 0)
                if let acompletion = older.completion {
                    acompletion(false)
                }
            }
        #endif
    }
    
    /// The function will call a given completion block when the specified string is logged
    ///
    /// The function saves the string to expect for MAX_CACHE_SIZE_CALLS.
    /// The function is used to catch future logs
    /// If during these series of calls the string expected did occur, will call the completionBlock with true and will surpress the original log
    /// If during these series of calls the string expected did not occur, will call the completionBlock with false
    /// - Parameters:
    ///   - containedString: the string to look for in future log calls
    ///   - completion: the completion block to call when the string is encountered in a log call
    public func testingExpect(containedString:String, completion: @escaping Completion) {
        #if TESTING
            // Add new completion to see if it will be called in the future
            MNLogger.stringsToExpect.append((text: containedString, step:MNLogger.expectStepCounter, completion:completion))
            
            if (MNLogger.stringsToExpect.count > MNLogger.MAX_CACHE_SIZE) {
                // Pop oldest completion as failed
                let older = MNLogger.stringsToExpect.remove(at: 0)
                if let acompletion = older.completion {
                    acompletion(false)
                }
            }
        #endif
    }
    
    /// Clears all future loggin testing expectations without logging or calling expecation completions
    /// The function is used to catch future logs
    public func clearTestingExpectations() {
        MNLogger.expectStepCounter = 0
        MNLogger.stringsToExpect.removeAll()
    }
    
    private func isShouldPrintLog(_ item : MNLogItem)->Bool {
        guard Self.IS_LOGS else {
            return true
        }
        
        // Will always allow log for items of the given levels
        if MNLogger.alwaysPrinted.contains(item.level) {
            return true
        }
        
        // Will fiter items based on their granularity / verbosity
        if !self.isGranularityAllowed(item.granularity) {
            return false
        }
        
        // Will fiter items based on their existance in the filter
        // When the filter is empty, will log all items
        if MNLogger.filterIn.count > 0 {
            // When our log message has a key in common with filterIn, it should log
            return MNLogger.filterIn.intersection(self.keys).count > 0
        } else if MNLogger.filterOut.count > 0 {
            // When our log message has a key in common with filterOut, it should NOT log
            return MNLogger.filterOut.intersection(self.keys).count == 0
        } else {
            return true
        }
        
        // Will not log this line
        // WILL NEVER BE EXECUTED // return false
    }
    
    /// Determine if a log is to be printed out or surpressed, passed to the testing expect system
    /// For private use (internal to this class)
    private func isShouldSurpressLog(_ item :MNLogItem)->Bool {
        guard Self.IS_LOGS else {
            return true
        }
        
        var result = false
        
        #if TESTING
            let stringsToExpect = MNLogger.stringsToExpect
            if (stringsToExpect.count > 0) {
                // Search if any expected srting is part of the given log string
                var foundIndex : Int? = nil
                var itemsToFail:[Int] = []
                
                for (index, item) in stringsToExpect.enumerated() {
                    if text.contains(item.text) {
                        // Found an expected string contained in the given log
                        foundIndex = index
                    }
                    
                    if (MNLogger.expectStepCounter - item.step > MNLogger.MAX_EXPECT_WAIT) {
                        itemsToFail.append(index)
                    }
                }
                
                if let index = foundIndex {
                    // We remove the expected string from the waiting list
                    let item = MNLogger.stringsToExpect.remove(at: index)
                    
                    // We call the expected string with a completion
                    if let acompletion = item.completion {
                        acompletion(true)
                    }
                    
                    result = true
                }
                
                for index in itemsToFail {
                    // We remove the expected string from the waiting list
                    let item = MNLogger.stringsToExpect.remove(at: index)
                    
                    // We call the expected string with a completion
                    if let acompletion = item.completion {
                        acompletion(false)
                    }
                }
            }
            
        MNLogger.expectStepCounter += 1
        #endif
        
        // Print w/ filter
        if self.isShouldPrintLog(item) == false {
            result = true
        }
        
        return result // whwn not testing, should not supress log?
    }
    
    // MARK: Private
    
    private func logLineHeader()->String {
        return MNLogger.dateFormatter.string(from: Date()) + " | [" + self.keys.joined(separator: ".") + "] "
    }
    
    
    /// Actual logging implementation using Swift.print
    /// - Parameter item: Log item to print to console
    private func println(_ item: MNLogItem) {
        let allLines : [String] = item.items.flatMap { str in
            str.components(separatedBy: "\n")
        }
        for line in allLines {
            //NSLog(s)
            print(logLineHeader() + line.trimmingCharacters(in: ["\""]))
        }
    }
    
    
    /// Actual logging implementation using Swift.print for use when IS\_DEBUG is active
    /// - Parameter item:Log item to print to console
    private func debugPrintln(_ item: MNLogItem)  {
        let allLines : [String] = item.items.flatMap { str in
            str.components(separatedBy: "\n")
        }
        for line in allLines {
            //NSLog(s)
            print(logLineHeader() + line.trimmingCharacters(in: ["\""]))
        }
    }
    
//    private func stringFromAny(_ value:Any?) -> String {
//
//        if let nonNil = value, !(nonNil is NSNull) {
//
//            return String(describing: nonNil)
//        }
//
//        return ""
//    }
    
    
    fileprivate func infoWithIndent(_ items: [String], indent: Int) {
        let indentStr = String(repeating: " ", count: indent)
        let indentedItems = items.map { str in
            return indentStr + str
        }
        let item = MNLogItem(self.curGranularity, .info, items: indentedItems)
        if (!isShouldSurpressLog(item)) {
            debugPrintln(item)
        }
    }
    
    /// Log items as an informative log call
    ///
    /// - Parameters:
    ///   - items: Items to log
    ///   - indent: indent level
    public func infoWithIndent(_ items: String..., indent: Int) {
        self.infoWithIndent(items, indent: indent)
    }
    
    /// Log items as an informative log call
    /// indent level is 0
    ///
    /// - Parameters:
    ///   - items: Items to log
    public func info(_ items: String...) {
        self.infoWithIndent(items, indent: 0)
    }
    
    fileprivate func info(items: [String]) {
        self.infoWithIndent(items, indent: 0)
    }
    
    /// Log items as a "success" log call. Will prefix a for section:checkmark (✔) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func success(_ items: String...) {
        self.success(items:items)
    }
    
    fileprivate func success(items: [String]) {
        let item = MNLogItem(self.curGranularity, .success, items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // "✔ \(items)"
        }
    }
    
    /// Log items as a "fail" log call. Will prefix a red x mark (✘) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func fail(_ items: String...) {
        self.fail(items: items)
    }
    
    fileprivate func fail(items: [String]) {
        let item = MNLogItem(self.curGranularity, .fail, items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // "✘ \(items)"
        }
    }
    
    public func successOrFail(condition:Bool,_ items: String...) {
        self.successOrFail(condition: condition, items: items)
    }
    
    fileprivate func successOrFail(condition:Bool, items: [String]) {
        let item = MNLogItem(self.curGranularity, (condition ? .success : .fail), items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // ✘ or ✔ followed by " \(items)"
        }
    }
                                                            
    public func successOrFail(condition:Bool, succStr: String..., failStr:String...) {
        
        let item = MNLogItem(self.curGranularity,
                             (condition ? .success : .fail),
                             items:  (condition ? succStr : failStr))
        
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // ✘ or ✔ followed by " \(items)"
        }
    }
    /// Log items as a "note" log call. Will prefix an orange warning sign (⚠️️) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func note(_ items: String...) {
        self.note(items:items)
    }
    
    fileprivate func note(items: [String]) {
        let item = MNLogItem(self.curGranularity, .note, items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // "⚠️️ \(items)"
        }
    }
    
    /// Log items as a "todo" log call. Will prefix with a TODO: (👁 TODO:) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func todo(_ items: String...) {
        self.todo(items: items)
    }
    
    fileprivate func todo(items: [String]) {
        let item = MNLogItem(self.curGranularity, .todo, items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item) // "👁 \(items)"
        }
    }

    /// Log items as a "warning" log call. Will prefix a red exclemation mark (❗) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func warning(_ items: String...) {
        self.warning(items: items)
    }
    
    public func warning(items: [String]) {
        let item = MNLogItem(self.curGranularity, .warning, items: items)
        if !isShouldSurpressLog(item) {
            println(item) // "❗ \(items)"
        }
    }
    
    /// Log items as a "raisePreconditionFailure" log call. Will prefix a big red X mark (❌) before the logged string.
    /// Will first log and only then raise the precondition failure
    ///
    /// - Parameter items: Items to log.
    public func raisePreconditionFailure(_ items: @autoclosure ()->[String]) {
        let item = MNLogItem(self.curGranularity, .raisePrecondition, items: items())
        if !isShouldSurpressLog(item) {
            println(item) // "❗ \(items)"
            preconditionFailure("MNLog.fatal: \(items())")
        }
    }
    
    public func raisePreconditionFailure(_ item: @autoclosure ()->String) {
        return self.raisePreconditionFailure([item()])
    }
    
    /// Log items as a "raiseAssertFailure" log call. Will prefix a big red X mark (❌) before the logged string.
    /// Will first log and only then raise the assertion failure
    ///
    /// - Parameter items: Items to log
    public func raiseAssertFailure(_ items: @autoclosure ()->[String]) {
        let item = MNLogItem(self.curGranularity, .assertFailure, items: items())
        if !isShouldSurpressLog(item) {
            println(item) // "❌ \(items)"
            preconditionFailure("MNLog.fatal: \(items())")
        }
    }
    public func raiseAssertFailure(_ item: @autoclosure ()->String) {
        return self.raiseAssertFailure([item()])
    }
    
    
    // MARK: Log using custom granulairty, not the current granularity
    private func _granular(level:MNLogLevel = .info, granularity:MNLogGranularity = .default, items: [String]) {
        let item = MNLogItem(granularity, level, items: items)
        if !isShouldSurpressLog(item) {
            debugPrintln(item)
        }
    }
    
    public func granular(level:MNLogLevel = .info, items : [String]) {
        self._granular(level: level, granularity: self.curGranularity, items: items)
    }
    
    public func granular(level:MNLogLevel = .info, items : String...) {
        self._granular(level: level, granularity: self.curGranularity, items: items)
    }
    
    // MARK: Verbose conveniences
    fileprivate func verbose(level:MNLogLevel = .info, items : [String]) {
        self._granular(level: level, granularity: .verbose, items: items)
    }
    
    public func verbose(level:MNLogLevel = .info, items : String...) {
        self._granular(level: level, granularity: .verbose, items: items)
    }
    
    public var isVerboseActive : Bool {
        get {
            return self.isGranularityAllowed(.verbose)
        }
        set {
            let cur = self.isGranularityAllowed(.verbose)
            self.setting(granularity: cur ? .default : .verbose)
        }
    }
}

/// Logger utility for swift
public enum MNLog : String {
    
    // Basic activity
    case appDelegate = "appDelegate"
    case misc = "misc"
    case ui = "ui"
    case db = "db"
    case util = "util"
    case accounts = "accounts"
    case api = "api"
    case url = "url"
    case settings = "settings"
    
    // Testing
    case testing = "testing"
    
    // MARK: Public logging functions
    private static var instances : [String:MNLogger] = [:]
    private static var instancesLock = NSRecursiveLock()
    
    static private func instance(keys : MNLogKeys, handle:(_ instance: MNLogger)->Void) {
        let key = keys.joined(separator: ".")
        instancesLock.lock {
            if let instance = MNLog.instances[key] {
                handle(instance)
            } else {
                let instance = MNLogger(keys: keys)
                MNLog.instances[key] = instance
                handle(instance)
            }
        }
    }
    
    // Get an instance of a logger by its key:
    static private func instance(key : String, handle:(_ instance: MNLogger)->Void) {
        MNLog.instance(keys: [key], handle:handle)
    }
    
    public func info(_ items: String..., indent: Int = 0) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.infoWithIndent(items, indent: indent)
        }
    }
    
    public func success(_ items: String) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.success(items)
        }
    }
    
    public func fail(_ items: String) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.fail(items)
        }
    }
    
    public func note(_ items: String) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.note(items)
        }
    }
    
    public func todo(_ items: String) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.todo(items)
        }
    }
    
    public func verbose(level: MNLogLevel = .info,_ items: String...) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.verbose(level: level, items: items)
        }
    }
    
    /// Log items as a "warning" log call. Will prefix a red exclemation mark (❗) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func warning(_ items: String) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.warning(items)
        }
    }
    
    /// Log items as a "raisePreconditionFailure" log call. Will prefix a big red X mark (❌) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func raisePreconditionFailure(_ items: @autoclosure ()->[String]) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.raisePreconditionFailure(items())
        }
    }
    
    public func raiseAssertFailure(_ items: @autoclosure ()->[String]) {
        MNLog.instance(key: self.rawValue) { (instance) in
            instance.raiseAssertFailure(items())
        }
    }
    
    // MARK: Static logs - no instance creted! ("*" is the MNLog.instance's "key")
    public static func info(_ items: String..., indent: Int = 0) {
        MNLog.instance(key: "*") { (instance) in
            instance.infoWithIndent(items, indent: indent)
        }
    }
    
    public static func success(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.success(items:items)
        }
    }
    
    public static func fail(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.fail(items:items)
        }
    }
    
    public static func note(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.note(items:items)
        }
    }
    
    public static func todo(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.todo(items:items)
        }
    }
    
    public static func warning(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.warning(items:items)
        }
    }
    
    public static func raisePreconditionFailure(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.raisePreconditionFailure(items)
        }
    }
    
    public static func raiseAssertFailure(_ items: String...) {
        MNLog.instance(key: "*") { (instance) in
            instance.raiseAssertFailure(items)
        }
    }
    
    public static func filterKeys(_ keys:MNLogKeys) {
        MNLogger.filterOutKeys(keys)
    }
    
    public static func unfilterKeys(_ keys:MNLogKeys) {
        MNLogger.unfilterOutKeys(keys)
    }
    
    public static func forClass(_ name:String)->MNLogger? {
        guard MNLogger.IS_LOGS else {
            return nil
        }
        
        var result : MNLogger? = nil
        MNLog.instance(key: name) { (instance) in
            result = instance
        }
        
        // TODO: Not thread safe:
        return result
    }
    
    public static func forKeys(_ keys:String...)->MNLogger? {
        guard MNLogger.IS_LOGS else {
            return nil
        }
        
        var result : MNLogger? = nil
        MNLog.instance(keys: keys) { (instance) in
            result = instance
        }
        
        // TODO: Not thread safe:
        return result
    }
    
    public subscript(keys : String...) -> MNLogger? {
        get {
            guard MNLogger.IS_LOGS else {
                return nil
            }
            
            var allKeys : [String] = [self.rawValue]
            allKeys.append(contentsOf: keys)
            
            // TODO: Not thread safe:
            return MNLog.forKeys(allKeys.joined(separator: "."))
        }
    }
    
    // MARK: Indents
    static func indentedBlock(logger:MNLogger?, _ block:()->Void) {
        logger?.indentLevel += 1
        block()
        logger?.indentLevel -= 1
    }
    
    static func indentStart(logger:MNLogger?) {
        logger?.indentLevel += 1
    }
    
    static func indentEnd(logger:MNLogger?) {
        logger?.indentLevel -= 1
    }
}
