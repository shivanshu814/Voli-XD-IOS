//
//  User.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct User {
    var id = ""
    var displayName = ""
    var firstName = ""
    var lastName = ""
    var profileImageUrl = ""
    var thumbnail = ""
    var location = ""
    var city = ""
    var state = ""
    var country = ""
    var email = ""
    var countryCode = ""
    var phone = ""
    var tags = [String]()
    var itineraryCount = 0
    var followerCount = 0
    var followingCount = 0
    var followingUsers = [User]()
    var about = ""
    var fbId = ""
    var loginType = ""
    var isDirty = false
    var likedItineraries = [String]()
    var likedComments = [String]()
    var savedItineraries = [[String: String]]()
    var commentedItineraries = [String]()
    var followingUserIds = [String]()
    var token = ""
    var setting = [
                      Setting(title: "Itinerary visibility", isEnabled: true),
                      Setting(title: "Private messaging", isEnabled: false),
                      Setting(title: "Comment, Save, Like", isEnabled: true),
                      Setting(title: "Private message", isEnabled: true),
                      Setting(title: "New follower", isEnabled: true),
                      Setting(title: "Itinerary shared with you", isEnabled: true)]
    
    var short_dict: [String: Any] {
        return [
            "id": id,
            "thumbnail": thumbnail,
            "profileImageUrl": profileImageUrl,
            "displayName": displayName,
            "location": location,
            "lastUpdated": Date().timeIntervalSince1970
        ]
    }
    
    var chat_dict: [String: Any] {
        return [
            "id": id,
            "thumbnail": thumbnail,
            "displayName": displayName            
        ]
    }
    
    var keywords: [String] {
        var _keywords = displayName.lowercased().components(separatedBy: " ")
        _keywords.append(displayName.lowercased())
        if displayName.isEmpty {
            _keywords.removeAll()
        }
        _keywords.append(contentsOf: tags.map{$0.lowercased()})
        if !city.isEmpty && !_keywords.contains(city.lowercased()) {
            _keywords.append(city.lowercased())
        }
        if !state.isEmpty && !_keywords.contains(state.lowercased()) {
            _keywords.append(state.lowercased())
        }
        if !country.isEmpty && !_keywords.contains(country.lowercased()) {
            _keywords.append(country.lowercased())
        }
        if !location.isEmpty && !_keywords.contains(location.lowercased()) {
            _keywords.append(location.lowercased())
        }
        
        return _keywords
    }
    
    var atcUser: ATCUser {
        return ATCUser(uid: id, firstName: displayName, lastName: "", avatarURL: thumbnail, email: email, isOnline: true, user: self)
    }
    
    var isItineraryPrivate: Bool {
        return !((setting.filter{$0.title == "Itinerary visibility"}).first?.isEnabled ?? true)
    }
    
    var isPrivate: Bool {
        return !((setting.filter{$0.title == "Private messaging"}).first?.isEnabled ?? false)
    }
    
    var isCommentSaveLikeEnabled: Bool {
        return (setting.filter{$0.title == "Comment, Save, Like"}).first?.isEnabled ?? true
    }
    
    var isPrivateMessageEnabled: Bool {
        return (setting.filter{$0.title == "Private message"}).first?.isEnabled ?? true
    }
    
    var isNewfollowerEnabled: Bool {
        return (setting.filter{$0.title == "New follower"}).first?.isEnabled ?? true
    }
    
    var isItinerarySharedEnabled: Bool {
        return (setting.filter{$0.title == "Itinerary shared with you"}).first?.isEnabled ?? true
    }
    
    // MARK: - Init
    init() {}
    
    init(id: String, displayName: String, firstName: String, lastName: String, profileImageUrl: String, thumbnail: String = "", location: String, city: String = "", state: String = "", country: String = "", email: String, countryCode: String = "", phone: String, tags: [String], itineraryCount: Int, followerCount: Int, followingCount: Int, followingUsers: [User], about: String, fbId: String, setting: [Setting], loginType: String) {
        self.id = id
        self.displayName = displayName        
        self.profileImageUrl = profileImageUrl
        self.thumbnail = thumbnail
        self.location = location
        self.city = city
        self.state = state
        self.country = country
        self.tags = tags
        self.itineraryCount = itineraryCount
        self.email = email
        self.phone = phone
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.followingUsers = followingUsers
        self.about = about
        self.fbId = fbId
        self.setting = setting
        self.loginType = loginType
        
    }
    
    init(id: String, displayName: String, firstName: String, lastName: String, profileImageUrl: String, thumbnail: String = "", location: String, city: String = "", state: String = "", country: String = "", email: String,countryCode: String = "", phone: String, fbId: String, loginType: String) {
        self.id = id
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.thumbnail = thumbnail
        self.location = location
        self.city = city
        self.state = state
        self.country = country
        self.email = email
        self.phone = phone
        self.fbId = fbId
        self.loginType = loginType
    }
    
    init(data: [String : Any]) {
        self.id = data["id"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.thumbnail = data["thumbnail"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.city = data["city"] as? String ?? ""
        self.state = data["state"] as? String ?? ""
        self.country = data["country"] as? String ?? ""
        self.tags = data["tags"] as? [String] ?? []
        self.itineraryCount = data["itineraryCount"] as? Int ?? 0
        self.email = data["email"] as? String ?? ""
        self.countryCode = data["countryCode"] as? String ?? ""
        self.phone = data["phone"] as? String ?? ""
        self.followerCount = data["followerCount"] as? Int ?? 0
        self.followingCount = data["followingCount"] as? Int ?? 0
        self.followingUsers = data["followingUsers"] as? [User] ?? []
        self.about = data["about"] as? String ?? ""
        self.fbId = data["fbId"] as? String ?? ""
        
        let savedSetting = (data["setting"] as? [[String: Bool]] ?? [[String: Bool]]()).map{Setting(title: $0.keys.first ?? "", isEnabled: $0.values.first ?? false)}
        for item in setting {
            if let isEnabled = (savedSetting.filter{$0.title == item.title}).first?.isEnabled {
                let newSetting = Setting(title: item.title, isEnabled: isEnabled)
                if let index = setting.firstIndex(of: newSetting) {
                    setting[index] = newSetting
                }
            }
        }
        self.loginType = data["loginType"] as? String ?? "email"
        self.isDirty = data["isDirty"] as? Bool ?? false
        self.token = data["token"] as? String ?? ""
        
    }
}


extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
