//
//  DateFormatterEx.swift
//  
//
//  Created by Ido Rabin on 17/05/2023.
//  Copyright © 2022 . All rights reserved.
//

import Foundation

fileprivate let IS_MODIFIED_INT64_IN_MILLISECONDS = false
fileprivate var dateFormattersByDateFormat : [String:DateFormatter] = [:]
fileprivate var _localeHourFormatter:DateFormatter? = nil
fileprivate var _localeDateFormatter:DateFormatter? = nil
fileprivate var _localeDateYearFormatter:DateFormatter? = nil
fileprivate var _intlDateFormatter:DateFormatter? = nil // for debugging and support
fileprivate var _iso8601DateFormatter : ISO8601DateFormatter? = nil
fileprivate var _lock = NSRecursiveLock()

public extension Date {
    
    
    /// Convenience property: returns true when this date is in the future for current calendar and local time.
    /// The internal test is self.timeIntervalSinceNow > 0.0
    var isFutureDate : Bool {
        return self.timeIntervalSinceNow > 0.0
    }
    
    var isMidnightDate : Bool {
        let comps : DateComponents = Calendar.current.dateComponents([.hour, .minute, .second, .timeZone], from: self)
        var sum = (comps.hour ?? 0)
        sum += (comps.minute ?? 0)
        sum += (comps.second ?? 0)
        return sum == 0
    }
    
    /// Return true only if this date is later choronologically than the other date. Equal dates return false
    /// - Parameter otherDate: otehr date to compare with
    /// - Returns: return true when this date (self) is later (younger) than the other date
    func isLaterThan(otherDate:Date)->Bool {
        return self.compare(otherDate) == .orderedAscending
    }
    
    /// Return true only if this date is later or exactly the same choronologically as the other date. Equal dates return true
    /// - Parameter otherDate: otehr date to compare with
    /// - Returns: return true when this date (self) is later (younger) or the same as the other date
    func isLaterOrEqual(otherDate:Date)->Bool {
        return self.compare(otherDate) != .orderedAscending
    }
}

public extension DateFormatter {
    
    /// Conveniene init with a given string date format
    ///
    /// - Parameter newDateFormat: date format
    convenience init(dateFormat newDateFormat:String) {
        self.init()
        self.dateFormat = newDateFormat
        dateFormattersByDateFormat[newDateFormat] = self
    }
    
    private static var timeIntervalFormatterHHMMSS : DateComponentsFormatter? = nil
    class func timeIntervalHHMMSS(_ duration: TimeInterval?) -> String? {
        guard let duration = duration else {
            return nil
        }
        if DateFormatter.timeIntervalFormatterHHMMSS == nil {
            DateFormatter.timeIntervalFormatterHHMMSS = DateComponentsFormatter()
            DateFormatter.timeIntervalFormatterHHMMSS!.zeroFormattingBehavior = .pad
            DateFormatter.timeIntervalFormatterHHMMSS!.allowedUnits = [.hour, .minute, .second]
        }
        
        return DateFormatter.timeIntervalFormatterHHMMSS!.string(from: duration)?.trimmingPrefix("00")
    }
    
    private static var timeIntervalFormatterHHMM : DateComponentsFormatter? = nil
    class func timeIntervalHHMM(_ duration: TimeInterval?) -> String? {
        guard let duration = duration else {
            return nil
        }
        if DateFormatter.timeIntervalFormatterHHMM == nil {
            DateFormatter.timeIntervalFormatterHHMM = DateComponentsFormatter()
            DateFormatter.timeIntervalFormatterHHMM!.zeroFormattingBehavior = .pad
            DateFormatter.timeIntervalFormatterHHMM!.allowedUnits = [.hour, .minute, .second]
        }
        
        return DateFormatter.timeIntervalFormatterHHMM!.string(from: duration)
    }
    
    class func formatterByDateFormatString(_ dateFormat:String)->DateFormatter {
        if let formatter = dateFormattersByDateFormat[dateFormat] {
            return formatter
        }
        let fmtr = DateFormatter(dateFormat:dateFormat)
        fmtr.timeZone = Calendar.current.timeZone
        return fmtr
    }
    
    class var localeDateFormatter:DateFormatter {
        if _localeDateFormatter == nil {
            _localeDateFormatter = DateFormatter()
            _localeDateFormatter?.dateStyle = .medium
            _localeDateFormatter?.timeStyle = .none
            _localeDateFormatter?.timeZone = Calendar.current.timeZone
        }
        return _localeDateFormatter!
    }
    
    class var localeHourFormatter:DateFormatter {
        if _localeHourFormatter == nil {
            _localeHourFormatter = DateFormatter()
            _localeHourFormatter?.dateStyle = .none
            _localeHourFormatter?.timeStyle = .short
            _localeHourFormatter?.timeZone = Calendar.current.timeZone
        }
        return _localeHourFormatter!
    }
    
    class var localeYearFormatter:DateFormatter {
        if _localeDateYearFormatter == nil {
            _localeDateYearFormatter = DateFormatter(dateFormat: "YYYY") // TODO check how to pull local year formatting from actulal local
            _localeDateYearFormatter?.timeZone = Calendar.current.timeZone
        }
        return _localeDateYearFormatter!
    }
    
    class var intlDateFormatter:DateFormatter {
        if _intlDateFormatter == nil {
            _intlDateFormatter = DateFormatter(dateFormat: "dd/MM/yy HH:mm:ss")
            _intlDateFormatter?.timeZone = Calendar.current.timeZone
        }
        return _intlDateFormatter!
    }
    
    class var shortDayNameFormatter:DateFormatter {
        return DateFormatter.formatterByDateFormatString("EEE")
    }
    
    class var longDayNameFormatter:DateFormatter {
        return DateFormatter.formatterByDateFormatString("EEEE")
    }
    
    class var iso8601DateFormatter:ISO8601DateFormatter {
        if _iso8601DateFormatter == nil {
            _iso8601DateFormatter = ISO8601DateFormatter()
        }
        return _iso8601DateFormatter!
    }
}

// Extension allowing unboxing of Int64 values as Dates Formatter
/// Protocol acting as a common API for all types of date formatters,
/// such as `DateFormatter` and `ISO8601DateFormatter`. (CodeExtended)
public protocol AnyDateFormatter {
    /// Format a string into a date
    func date(from string: String) -> Date?
    /// Format a date into a string
    func string(from date: Date) -> String
}

public class INT64toDateFormatter : AnyDateFormatter {
    
    /// Format a string into a date
    public func date(from string: String) -> Date?
    {
        if let intStr = Int64(string) {
            return format(unboxedValue: intStr)
        }
        return nil
    }
    
    /// Format a date into a string
    public func string(from date: Date) -> String {
        return "\(floor(date.timeIntervalSince1970))"
    }
    
    /// Unboxable conformance - will convert a date from an Int64 (seconds or miliseconds since 1970) to a Date via Unboxable protocol
    ///
    /// - Parameter unboxedValue: value as string
    /// - Returns: returned Date converted
    public func format(unboxedValue: Int64) -> Date? {
        return Date(timeIntervalSince1970: TimeInterval(Double(unboxedValue) * (IS_MODIFIED_INT64_IN_MILLISECONDS ? 1000.0 : 1.0)))
    }
    
    init(){}
}

public extension Date {
    
    init?(optionalTimeIntervalSinceReferenceDate:TimeInterval?) {
        guard let interval = optionalTimeIntervalSinceReferenceDate else {
            return nil
        }
        self.init(timeIntervalSinceReferenceDate:interval)
    }
    
    init?(optionalTimeIntervalSince1970:TimeInterval?) {
        guard let interval = optionalTimeIntervalSince1970 else {
            return nil
        }
        self.init(timeIntervalSince1970:interval)
    }
    
    /// Returns an Int64 number of seconds / miliseconds since 1970 for this date
    var timeIntervalSince1970Int64 : Int64 {
        return Int64(round(timeIntervalSince1970 * (IS_MODIFIED_INT64_IN_MILLISECONDS ? 1000.0 : 1.0)))
    }
}

