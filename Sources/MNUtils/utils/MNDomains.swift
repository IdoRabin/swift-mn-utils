//
//  MNDomains.swift
//
//
//  Created by Ido on 28/11/2023.
//

import Foundation

/// Util class for managing domains
public class MNDomains {
    public static var DEFAULT_DOMAIN : String = "com.\(Bundle.main.bundleName?.snakeCaseToCamelCase() ?? "")"
    
    public init() {
        
    }
    
    // Functions
    public static func sanitizeDomain(_ domain: String?)->String {
        var result : String = domain ?? MNDomains.DEFAULT_DOMAIN
        if let adomain = domain, adomain.isValidLocalhostIPAddress {
            // Localhost:
            result = MNDomains.DEFAULT_DOMAIN
        }
        return result
    }
}
