//
//  ATCUser.swift
//  AppTemplatesCore
//
//  Created by Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.
//

import Foundation

open class ATCUser: NSObject, ATCGenericBaseModel {

    var uid: String?
    var username: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var profilePictureURL: String?
    var isOnline: Bool
    var voliUser: User?

    init(uid: String = "", firstName: String, lastName: String, avatarURL: String = "", email: String = "", isOnline: Bool = false, user: User? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.uid = uid
        self.email = email
        self.profilePictureURL = avatarURL
        self.isOnline = isOnline
        self.voliUser = user
    }

    required public init(jsonDict: [String: Any]) {
        fatalError()
    }

//    public func mapping(map: Map) {
//        username            <- map["username"]
//        email               <- map["email"]
//        firstName           <- map["first_name"]
//        lastName            <- map["last_name"]
//        profilePictureURL   <- map["profile_picture"]
//    }

    public func fullName() -> String {
        guard let firstName = firstName, let lastName = lastName else { return "" }
        return "\(firstName) \(lastName)"
    }

    var initials: String {
        return uid ?? "?"
        
    }
}
