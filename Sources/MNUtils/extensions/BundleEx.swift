//
//  BundleEx.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation

public extension Bundle {
    
    var versionNumber: String? {
        var result = infoDictionary?["CFBundleShortVersionString"] as? String
        if (infoDictionary?.count ?? 0 == 0) {
            // Fallback
            result = MNUTILS_BUILD_VERSION.versionString(formattedWith: .fullVersion)
        }
        return result
    }
    
    var buildNumber: String? {
        var result = infoDictionary?["CFBundleVersion"] as? String
        if (infoDictionary?.count ?? 0 == 0) {
            // Fallback
            result = MNUTILS_BUILD_VERSION.metadata.first
        }
        return result
    }
    
    var fullVersion : String {
        var result = "\(self.versionNumber ?? "0").\(self.buildNumber ?? "0")"
        if (infoDictionary?.count ?? 0 == 0) {
            // Fallback
            result = MNUTILS_BUILD_VERSION.versionString(formattedWith:[.fullVersion, .includeMetadata, .includePrerelease])
        }
        return result
    }
    
    var bundleName: String? {
        /*
         property list key CFBundleName
         A user-visible short name for the bundle.
         Name: Bundle name
         
         property list key CFBundleDisplayName
         The user-visible name for the bundle, used by Siri and visible on the iOS Home screen.
         Name: Bundle display name
         
         property list key CFBundleSpokenName
         A replacement for the app name in text-to-speech operations.
         Name: Accessibility Bundle Name
         */
        var result : String? = ""
        
        // if (infoDictionary?.count ?? 0 == 0) {
        //     // Fallback
        // result = APP_NAME_STR
        // } else {
        let keys = ["CFBundleDisplayName", "CFBundleName", "CFBundleSpokenName"]
        for key in keys {
            let str = self.infoDictionary?[key] as? String;
            if (str?.count ?? 0 > 0) {
                result = str
                break;
            }
        }
        // }
        
        return result
    }
}
