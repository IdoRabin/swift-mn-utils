//
//  TimeIntervalEx.swift
//  Ido Rabin
//
// Created by Ido Rabin for Bricks on 17/1/2024.
//  Copyright © 2022 Ido Rabin. All rights reserved.
//

import Foundation

public extension TimeInterval {
    func asString(decimalPlaces:Int = 3)->String {
        return String(format: "%0.\(decimalPlaces)f", self) // %0.{3}f
    }
}
