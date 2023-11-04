//
//  Activity.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import GooglePlaces
import GoogleMaps

struct Activity: Equatable {
    var itineraryId = ""
    var attachments = [Attachment]()
    var tag = [String]()    
    var description = ""
    var timeSpend: TimeInterval = 0
    var startTime = Date()
    var location = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var subLocality = ""
    var isDummy = false
    var city = ""
    var state = ""
    var country = ""
    
//    var city: String {
//        return subLocality.replacingOccurrences(of: ", ", with: "|").split(separator: "|").first?.string ?? ""
//    }
//    var country: String {
//        return subLocality.replacingOccurrences(of: ", ", with: "|").split(separator: "|").last?.string ?? ""
//    }
    var dict: [String: Any] {
        return [
            "attachments": attachments.map{$0.dict},
            "tag": tag,
            "description": description,
            "timeSpend": timeSpend,
            "startTime": startTime.timeIntervalSince1970,
            "location": location,
            "subLocality": subLocality,
            "latitude": latitude,
            "longitude": longitude,
            "city": city.lowercased(),
            "state": state.lowercased(),
            "country": country.lowercased()
        ]
    }
    
    static var dummyActiviy: Activity {
        var activity = Activity()
        activity.isDummy = true
        return activity
    }
    
    // MARK: - Init
    init() {}
    
    init(itineraryId: String,
         attachments: [Attachment],
         tag: [String],
         description: String,
         timeSpend: TimeInterval,
         startTime: Date,
         location: String,
         latitude: Double,
         longitude: Double,
         subLocality: String) {
        
        self.itineraryId = itineraryId
        self.attachments = attachments
        self.tag = tag
        self.description = description
        self.timeSpend = timeSpend
        self.startTime = startTime
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.subLocality = subLocality
    }
    
    init(data: [String : Any]) {
        self.itineraryId = data["itineraryId"] as? String ?? ""
        self.tag = data["tag"] as? [String] ?? []
        self.description = data["description"] as? String ?? ""
        self.timeSpend = data["timeSpend"] as? TimeInterval ?? 0
        self.startTime = Date(timeIntervalSince1970: data["startTime"] as? TimeInterval ?? 0)        
        self.latitude = data["latitude"] as? Double ?? 0
        self.longitude = data["longitude"] as? Double ?? 0
        self.location = data["location"] as? String ?? ""
        self.subLocality = data["subLocality"] as? String ?? ""
        self.attachments = (data["attachments"] as? [[String : Any]])?.map{Attachment(data: $0)} ?? []
        self.city = data["city"] as? String ?? ""
        self.state = data["state"] as? String ?? ""
        self.country = data["country"] as? String ?? ""
        
    }
}
