//
//  DisplayStringable.swift
//  Knowz
//
//  Created by ido on 30/07/2024.
//

import Foundation

public typealias DisplayString = String

public enum DisplayDetail {
    case compact
    case regular
    case detailed
}

public protocol DisplayStringable {
    
    var displayString : DisplayString { get }
    
    func displayString(detail:DisplayDetail, multiline:Bool)->DisplayString
    func displayDetails()->[DisplayString]
}

extension DisplayStringable {
    public func displayString(detail:DisplayDetail = .regular, multiline:Bool = false)->DisplayString {
        return self.displayString
    }
    
    public func displayDetails()->[DisplayString] {
        let res = self.displayString(detail: .detailed, multiline: true).split(separator: "\n")
        return res.map{ DisplayString($0) }
    }
}
