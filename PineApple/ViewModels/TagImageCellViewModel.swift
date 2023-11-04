//
//  TagImageCellViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 7/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

class TagImageCellViewModel: ViewModel {
    
    enum ImageHeight: Int {
        case small
        case medium
        case high
        
        var height: Int {
            switch self {
            case .small: return 141
            case .medium: return 178
            case .high: return 295
            }
        }
    }
    
    var attachment: Attachment
    var imageHeight: ImageHeight
    var itinerary: Itinerary
    
    // MARK: - Init
    init(itinerary: Itinerary, attachment: Attachment, imageHeight: ImageHeight) {
        self.attachment = attachment
        self.imageHeight = imageHeight
        self.itinerary = itinerary
    }
}
