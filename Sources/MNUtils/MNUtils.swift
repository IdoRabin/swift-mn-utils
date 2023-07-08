import AppKit
import DSLogger

public struct MNUtils {
    
    public static let debug = MNDebug()
    public static let constants = MNConstants()
    
    // MARK: Singleton
}

public let mnUtils = MNUtils()

public class MNDebug {
    // TODO: Check if IS_DEBUG should be an @inlinable var ?
    public var IS_DEBUG = true
    
    fileprivate init(){
        
    }
    
    func StringOrNil(_ str:String)->String? {
        return self.IS_DEBUG ? str : nil
    }
    
    func StringOrEmpty(_ str:String)->String {
        return self.IS_DEBUG ? str : ""
    }
}

public class MNConstants {
    let dlog : MNLogger? = MNLog.forClass("MNUtils")
    
    public let BASE_64_PARAM_KEY = "e64"
    public let PROTOBUF_PARAM_KEY = "ptb"
    public let PERCENT_ESCAPED_HINTS = [
        "%3D" : "=",
        "%26" : "&",
        "%5F" : "_",
        "%25" : "%",
        "%7C" : "|",
        "%2D" : "-",
        "%20" : " ",
        "%2F" : "/",
    ]
    
    public let PERCENT_DOUBLY_ESCAPED_HINTS = [
        "%253D" : "=",
        "%2526" : "&",
        "%257C" : "|",
        "%252D" : "-",
        "%255F" : "_",
        "%2520" : " ",
        "%252F" : "/",
    ]
    
    public let IS_VAPOR_SERVER : Bool = {
        #if VAPOR
        return true
        #else
        return false
        #endif
    }()
    
    public var IS_RTL_LAYOUT : Bool = {
        #if VAPOR
        return false
        #else
        // TODO: detect cur language layout for this running appKit app?
        return false
        #endif
    }()
    
    fileprivate init() {
        
    }
}

public extension String {
    static let NBSP = "\u{00A0}"
    static let FIGURE_SPACE = "\u{2007}" // “Tabular width”, the width of digits
    static let IDEOGRAPHIC_SPACE = "\u{3000}" // The width of ideographic (CJK) characters.
    static let NBHypen = "\u{2011}"
    static let ZWSP = "\u{200B}" // Use with great care! ZERO WIDTH SPACE (HTML &#8203)
    
    static let SECTION_SIGN = "\u{00A7}" // § Section Sign: &#167; &#xA7; &sect; 0x00A7
    
    static let CRLF_KEYBOARD_SYMBOL = "\u{21B3}" // ↳ arrow down and right
}

public extension Date {
    static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    static let SECONDS_IN_A_DAY_INT : Int = 86400
    static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}

public extension TimeInterval {
    static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    static let SECONDS_IN_A_DAY_INT : Int = 86400
    static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}
