//
//  ItineraryFilterOption.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct ItineraryFilterOption {
    
    // MARK: - Properties    
    enum SortBy: Int {
        case createDate
        case popularity
        case duration
        case distance
        
        var displayName: String {
            switch self {
            case .createDate: return "Date created"
            case .popularity: return "Popularity"
            case .duration: return "Duration"
            case .distance: return "Distance from city centre"
            }
        }
        
        var fieldName: String {
            switch self {
            case .createDate: return "createdDate"
            case .popularity: return "likeCount"
            case .duration: return "duration"
            case .distance: return "distance"
            }
        }
        
        var descending: Bool {
            switch self {
            case .createDate: return true
            case .popularity: return true
            case .duration: return true
            case .distance: return false
            }
        }
    }
    
    var location: String = "sydney"
    var state: String = "nsw"
    var country: String = "australia"    
    var tags = [String]()
    var sortBy: SortBy = .createDate
    
    // MARK: - Init
    init() {}
    
    init(location: String, state: String, country: String, tags: [String], sortBy: SortBy) {
        self.location = location
        self.state = state
        self.country = country
        self.tags = tags
        self.sortBy = sortBy
    }
    
}
