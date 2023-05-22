//
//  URLEx.swift
//  
//
//  Created by Ido Rabin on 17/05/2023.
//  Copyright © 2022 . All rights reserved.
//

import Foundation

fileprivate let dlog : MNLogger? = MNLog.forClass("URLEx")

//extension URI {
//    
//}

extension URL {
    
    /// Return components of the url query (after the ?) as a dictionary
    ///
    /// - Returns: a dictionary of all query components
    func queryComponents() -> [String:String]? {
        var result : [String:String]? = [:]
        if let urlComponents = URLComponents(string: self.absoluteString), let queryItems = (urlComponents.queryItems) {
            for queryItem in queryItems {
                if (queryItem.name.count > 0) {
                    result![queryItem.name] = queryItem.value
                }
            }
            
            //return queryItems.filter({ (item) in item.name == param }).first?.value!
            if (result!.count > 0) {
                return result
            }
        }
        return nil
    }
    
    
    /// Return the last X path components for a given url
    ///
    /// - Parameter count: amount of suffixing components to return, delimited by "/"
    /// - Returns: String of last components, by order of appearance in the URL, joined by "/"
    func lastPathComponents(count:Int)->String {
        if count == 0 {return ""}
        let components = self.absoluteString.components(separatedBy: "/")
        let comps = components.suffix(min(count, components.count))
        return comps.joined(separator: "/")
    }
}

extension Sequence where Element == URLQueryItem {
    func asDictionary() -> [String:String]? {
        var result : [String:String] = [:]
        for queryItem in self {
            if (queryItem.name.count > 0) {
                result[queryItem.name] = queryItem.value
            }
        }
        return result
    }
}

extension URLComponents {
    
    func asDictionaey() -> [String:String]? {
        return self.queryItems?.asDictionary()
    }
}
