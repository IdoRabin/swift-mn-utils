//
//  File.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation

public protocol MNUserable {
    var id: UUID? { get }
    var username: String? { get }
    var email: String? { get }
    var domain: String? { get }
}
