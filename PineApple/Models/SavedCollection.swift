//
//  SavedCollection.swift
//  PineApple
//
//  Created by Tao Man Kit on 3/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct SavedCollection {
    var id: String
    var name: String
    var itineraries: [ItineraryDetailViewModel]
    var isDeleted = false
    
    // MARK: - Init
    init(id: String, name: String, itineraries: [ItineraryDetailViewModel]) {
        self.id = id
        self.name = name
        self.itineraries = itineraries
    }
    
    init(data: [String : Any]) {
        self.id = data["id"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        let _itineraries = data["itineraries"] as? [[String : Any]]
        self.itineraries = _itineraries?.map{ItineraryDetailViewModel(itinerary: Itinerary(data: $0))} ?? []
    }
}


extension SavedCollection: Equatable {
    static func == (lhs: SavedCollection, rhs: SavedCollection) -> Bool {
        return lhs.id == rhs.id
    }
}
