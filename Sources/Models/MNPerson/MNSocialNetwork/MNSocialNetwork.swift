//
//  MNSocialNetwork.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation

//
enum MNSocialNetwork: Int, CaseIterable, CodableHashable, JSONSerializable {
    case facebook
    case twitter
    case instagram
    case linkedIn
    case snapchat
    case pinterest
    case tumblr
    case reddit
    case tikTok
    case youtube
    case whatsapp
    case weChat
    case telegram
    case discord
    case medium
    case quora
    case vine
    case flickr
    case periscope
    case vkontakte

    func getHomeURL() -> String {
        switch self {
        case .facebook:
            return "https://www.facebook.com"
        case .twitter:
            return "https://www.twitter.com"
        case .instagram:
            return "https://www.instagram.com"
        case .linkedIn:
            return "https://www.linkedin.com"
        case .snapchat:
            return "https://www.snapchat.com"
        case .pinterest:
            return "https://www.pinterest.com"
        case .tumblr:
            return "https://www.tumblr.com"
        case .reddit:
            return "https://www.reddit.com"
        case .tikTok:
            return "https://www.tiktok.com"
        case .youtube:
            return "https://www.youtube.com"
        case .whatsapp:
            return "https://www.whatsapp.com"
        case .weChat:
            return "https://www.wechat.com"
        case .telegram:
            return "https://www.telegram.org"
        case .discord:
            return "https://www.discord.com"
        case .medium:
            return "https://www.medium.com"
        case .quora:
            return "https://www.quora.com"
        case .vine:
            return "https://www.vine.co"
        case .flickr:
            return "https://www.flickr.com"
        case .periscope:
            return "https://www.periscope.tv"
        case .vkontakte:
            return "https://www.vk.com"
        }
    }

    static var all: [SocialNetwork] {
        return Array(self.allCases)
    }
}
