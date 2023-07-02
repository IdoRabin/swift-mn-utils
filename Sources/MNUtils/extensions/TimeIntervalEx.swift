//
//  TimeIntervalEx.swift
//  Ido Rabin
//
//  Created by Ido on 01/08/2022.
//  Copyright © 2022 Ido Rabin. All rights reserved.
//

import Foundation

public extension TimeInterval {
    func asString(decimalPlaces:Int = 3)->String {
        return String(format: "%0.\(decimalPlaces)f", self) // %0.{3}f
    }
}
