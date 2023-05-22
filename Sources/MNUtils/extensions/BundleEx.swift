//
//  BundleEx.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation

extension Bundle {
    
    var versionNumber: String? {
        let result = infoDictionary?["CFBundleShortVersionString"] as? String
        // if (infoDictionary?.count ?? 0 == 0) {
        //     // Fallback
        //     result = APP_BUILD_VERSION.versionString(formattedWith: .fullVersion)
        // }
        return result
    }
    
    var buildNumber: String? {
        let result = infoDictionary?["CFBundleVersion"] as? String
        // if (infoDictionary?.count ?? 0 == 0) {
        //     // Fallback
        //     result = APP_BUILD_VERSION.metadata.first
        // }
        return result
    }
    
    public var fullVersion : String {
        let result = "\(self.versionNumber ?? "0").\(self.buildNumber ?? "0")"
        // if (infoDictionary?.count ?? 0 == 0) {
        //     // Fallback
        //     result = APP_BUILD_VERSION.versionString(formattedWith:[.fullVersion, .includeMetadata, .includePrerelease])
        // }
        return result
    }
    
    public var bundleName: String? {
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
