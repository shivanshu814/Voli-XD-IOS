//
//  Constant.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

// MARK: - Constant

let URL_UPDATE_USER = "https://us-central1-voli-xd.cloudfunctions.net/updateUser"
let URL_UPDATE_FOLLOWING = "https://us-central1-voli-xd.cloudfunctions.net/updateFollowing"
let URL_UPDATE_CHANNELS = "https://us-central1-voli-xd.cloudfunctions.net/updateChannels"
let URL_UPDATE_ITINERARY = "https://us-central1-voli-xd.cloudfunctions.net/updateItinerary"
let ISENABLED_CHAT = true
let SEARCH_PATH = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true).first!
let bundleID = "com.quadrant.volixd"
let appStoreID = "1480514902"
let dynamicLinksDomainURIPrefix = "https://volixd.page.link"
let appIconURL = "https://dl.dropbox.com/s/jqwqwensc681ed1/Icon-App-iTunes.png"
let WORLDWIDE = "Worldwide"
let CURRENT_LOCATION = "Current location"
let coverVideo = "CoverVideo"

let sortByOption: [ItineraryFilterOption.SortBy] = [
    .createDate,
    .popularity,
    .duration,
    .distance
]

let locationOption = [
    Location(shortName: "Worldwide", longName: "Worldwide"),
    Location(shortName: "Current location", longName: "Current location"),
    Location(shortName: "Sydney", longName: "Sydney, NSW, Australia"),
    Location(shortName: "Melbourne", longName: "Melbourne, VIC, Australia"),
    Location(shortName: "Hong Kong", longName: "Hong Kong"),
    Location(shortName: "New York", longName: "New York, NY, USA"),
]

extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
    static let locationPermissionDidChanged = Notification.Name("locationPermissionDidChanged")
    static let locationUpdated = Notification.Name("locationUpdated")
    static let didItineraryDidUpdated = Notification.Name("didItineraryDidUpdated")
    static let didUserDidUpdated = Notification.Name("didUserDidUpdated")
    static let didCommentDidUpdated = Notification.Name("didCommentDidUpdated")
    static let didCollectionDidUpdated = Notification.Name("didCollectionDidUpdated")
    static let sharedCollectionDidReceived = Notification.Name("sharedCollectionDidReceived")
    static let messageDidReceived = Notification.Name("messageDidReceived")
}

enum DynamicLinkType: Int {
    case itinerary
    case profile
    case collection
    
    func url(id: String, name: String? = nil) -> URL? {
        var path = ""
        switch self {
        case .itinerary: path = "itinerary/\(id)"
        case .profile: path = "profile/\(id)"
        case .collection: path = "collection/\(id)/\(Globals.currentUser!.id)/\(name!.urlEncoded)"
        }
        return URL(string: "https://www.volixd.com/" + path)
    }
}
