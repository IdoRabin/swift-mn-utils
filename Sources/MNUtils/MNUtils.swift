import AppKit

public struct MNUtils {
    
    static let debug = MNDebug()
    static let constants = MNConstants()
    
    // MARK: Singleton
}

let mnUtils = MNUtils()


class MNDebug {
    var IS_DEBUG = true
    
    fileprivate init(){
        
    }
}

class MNConstants {
    let dlog : MNLogger? = MNLog.forClass("MNUtils")
    
    let BASE_64_PARAM_KEY = "e64"
    let PROTOBUF_PARAM_KEY = "ptb"
    let PERCENT_ESCAPED_HINTS = [
        "%3D" : "=",
        "%26" : "&",
        "%5F" : "_",
        "%25" : "%",
        "%7C" : "|",
        "%2D" : "-",
        "%20" : " ",
        "%2F" : "/",
    ]
    
    let PERCENT_DOUBLY_ESCAPED_HINTS = [
        "%253D" : "=",
        "%2526" : "&",
        "%257C" : "|",
        "%252D" : "-",
        "%255F" : "_",
        "%2520" : " ",
        "%252F" : "/",
    ]
    
    let IS_VAPOR_SERVER : Bool = {
        #if VAPOR
        return true
        #else
        return false
        #endif
    }()
    
    var IS_RTL_LAYOUT : Bool = {
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

extension String {
    public static let NBSP = "\u{00A0}"
    public static let FIGURE_SPACE = "\u{2007}" // “Tabular width”, the width of digits
    public static let IDEOGRAPHIC_SPACE = "\u{3000}" // The width of ideographic (CJK) characters.
    public static let NBHypen = "\u{2011}"
    public static let ZWSP = "\u{200B}" // Use with great care! ZERO WIDTH SPACE (HTML &#8203)
    
    public static let SECTION_SIGN = "\u{00A7}" // § Section Sign: &#167; &#xA7; &sect; 0x00A7
    
    public static let CRLF_KEYBOARD_SYMBOL = "\u{21B3}" // ↳ arrow down and right
}

extension Date {
    public static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    public static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    public static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    public static let SECONDS_IN_A_DAY_INT : Int = 86400
    public static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    public static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    public static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    public static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    public static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}

extension TimeInterval {
    public static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    public static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    public static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    public static let SECONDS_IN_A_DAY_INT : Int = 86400
    public static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    public static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    public static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    public static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    public static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}
