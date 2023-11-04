//
//  Itinerary.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct Itinerary {
    var id = ""
    var title = ""
    var description = ""
    var heroImage = ""
    var heroImageThumbnail = ""
    var coverVideo = ""
    var activities = [Activity]()
    var user = User()    
    var isLike = false
    var isSave = false
    var isCommented = false
    var likeCount: Int = 0
    var commentCount: Int = 0
    var savedCount: Int = 0
    var isPrivate = false
    var isAllowContact = false
    var createDate = Date()
    var distance: Int = 99999
    var isDeleted = false
    
    var city: String {
        return activities.first?.city.lowercased() ?? ""
    }
    
    var state: String {
        return activities.first?.state.lowercased() ?? ""
    }
    
    var country: String {
        return activities.first?.country.lowercased() ?? ""
    }
    
    var tags: [String] {
        var _tags = [String]()
        activities.forEach {
            for tag in $0.tag {
                if !_tags.contains(tag) {
                    _tags.append(tag)
                }
            }
        }
        return _tags
    }
    
    var keywords: [String] {
        // Keywords: Title, Location and Tags
        var keywords = title.split(separator: " ").map{String($0).lowercased()}
        keywords.append(title.lowercased())
        tags.forEach {
            if !keywords.contains($0.lowercased()) {
                keywords.append($0.lowercased())
            }
            var _keywords = $0.split(separator: " ").map{String($0).lowercased()}
            _keywords.forEach {
                if !keywords.contains($0.lowercased()) {
                    keywords.append($0.lowercased())
                }
            }
            
        }
        
        if let subLocality = activities.first?.subLocality, let location = activities.first?.location {
            if !keywords.contains(location.lowercased()) {
                keywords.append(location.lowercased())
            }
            if !keywords.contains(subLocality.lowercased()) {
                keywords.append(subLocality.lowercased())
            }
            subLocality.lowercased().replacingOccurrences(of: ", ", with: "|")
                .split(separator: "|").forEach {
                    if !keywords.contains(String($0)) {
                        keywords.append(String($0))
                    }
            }
            if !city.isEmpty && !keywords.contains(city.lowercased()) {
                keywords.append(city.lowercased())
            }
            
            if !state.isEmpty && !keywords.contains(state.lowercased()) {
                keywords.append(state.lowercased())
            }
            if !country.isEmpty && !keywords.contains(country.lowercased()) {
                keywords.append(country.lowercased())
            }
        }
        return keywords
                
    }
    
    var duration: Int {
        let duration = activities.reduce(0) { (result, activity) -> Int in
            result + activity.timeSpend.int
        }
        return duration
    }
    
    var isOwner: Bool {
        return user.id == Globals.currentUser?.id
    }
    
    var dict: [String: Any] {
        return [
               "id": id,
               "title": title,
               "description": description,
               "heroImage": heroImage,
               "heroImageThumbnail": heroImageThumbnail,
               "coverVideo": coverVideo,
               "activities": activities.map{$0.dict},
               "user": user.short_dict,
               "isPrivate": isPrivate,
               "isAllowContact": isAllowContact,
               "duration": duration,
               "distance": distance,
               "likeCount" : likeCount,
               "commentCount" : commentCount,
               "savedCount" : savedCount,
               "createdDate": createDate.timeIntervalSince1970,
               "location": city,
               "state": city == "hong kong" ? "" : state,
               "country": country,
               "tags": tags,
               "searchTags": tags.map{$0.lowercased()},
               "keywords": keywords,
               "numShards": globalNumShards,
               "lastUpdated": Date().timeIntervalSince1970]
    }
    
    // MARK: - Init
    init() {
        self.user = Globals.currentUser ?? User()
    }
    
    init(id: String) {
        self.id = id
    }
    
    init(activities: [Activity]) {
        self.activities = activities
        self.user = Globals.currentUser ?? User()
    }
    
    init(id: String,
         title: String,
         description: String,
         heroImage: String,
         heroImageThumbnail: String,
         activities: [Activity],
         user: User,
         isLike: Bool,
         isSave: Bool,
         isCommented: Bool,
         likeCount: Int,
         commentCount: Int,
         savedCount: Int,
         createDate: Date,
         isPrivate: Bool,
         isAllowContact: Bool,
         distance: Int) {
        
        self.id = id
        self.title = title
        self.description = description
        self.heroImage = heroImage
        self.heroImageThumbnail = heroImageThumbnail
        self.activities = activities
        self.user = user
        self.isLike = isLike
        self.isSave = isSave
        self.isCommented = isCommented
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.savedCount = savedCount
        self.createDate = createDate
        self.isPrivate = isPrivate
        self.isAllowContact = isAllowContact
        self.distance = distance
        
    }
    
    init(data: [String : Any]) {
        self.id = data["id"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.heroImage = data["heroImage"] as? String ?? ""
        self.heroImageThumbnail = data["heroImageThumbnail"] as? String ?? ""
        var _activities = data["activities"] as? [[String : Any]]
        
        for i in 0..<(_activities?.count ?? 0) {
            _activities?[i]["itineraryId"] = self.id
        }
        self.activities = _activities?.map{Activity(data: $0)} ?? []
        if let _user = data["user"] as? [String : Any] {
            self.user = User(data: _user)
        }
        self.likeCount = data["likeCount"] as? Int ?? 0
        self.commentCount = data["commentCount"] as? Int ?? 0
        self.savedCount = data["savedCount"] as? Int ?? 0
        self.createDate = Date(timeIntervalSince1970: data["createdDate"] as? TimeInterval ?? 0)
        self.isPrivate = data["isPrivate"] as? Bool ?? false
        self.isAllowContact = data["isAllowContact"] as? Bool ?? false
        self.distance = data["distance"] as? Int ?? 0
        self.coverVideo = data["coverVideo"] as? String ?? ""
    }
}

extension Itinerary: Equatable {
    static func == (lhs: Itinerary, rhs: Itinerary) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Itinerary {
    mutating func updateLikeCommentSave() {
        isLike = Globals.currentUser?.likedItineraries.contains(id) ?? false
        isCommented = Globals.currentUser?.commentedItineraries.contains(id) ?? false
        isSave = (Globals.currentUser?.savedItineraries.map{$0.keys.first!})?.contains(id) ?? false
    }
}
