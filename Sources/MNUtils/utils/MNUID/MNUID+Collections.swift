//
//  MNUID+Collections.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation


// MARK: Sorting of MNUID arrays
public extension Array where Element : MNUIDProtocol {
    
    mutating func sort() {
        return self.sort { mnUID1, mnUID2 in
            return mnUID1 < mnUID2
        }
    }
    
    func sorted()->[Element] {
        return self.sorted { mnUID1, mnUID2 in
            return mnUID1 < mnUID2
        }
    }
    
    func contains(mnUID:Element?)->Bool {
        guard let mnUID = mnUID else {
            return false
        }
        return self.contains(mnUID)
    }
    
    func firstIndex(ofMNUID:Element?)->Int? {
        guard let mnUID = ofMNUID else {
            return nil
        }
        return self.firstIndex(of: mnUID)
    }
    
    func lastIndex(ofMNUID:Element?)->Int? {
        guard let mnUID = ofMNUID else {
            return nil
        }
        return self.lastIndex(of: mnUID)
    }
}
