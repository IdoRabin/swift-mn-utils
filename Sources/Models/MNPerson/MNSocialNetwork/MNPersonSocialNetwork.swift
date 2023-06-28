//
//  MNPersonSocialNetwork.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation

class MNPersonSocialNetwork : CodableHashable, JSONSerializable, Identifiable {
    var id : String
    
    var type : MNPersonSocialNetwork
    var userId {
        return id
    }
    var userName : String
    var email : String
    var accessToken : any Codable & CustomStringConvertible
    
}
