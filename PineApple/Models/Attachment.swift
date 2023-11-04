//
//  Attachment.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation
import DKImagePickerController

struct Attachment: Equatable {

    var path = ""
    var thumbnail = ""
    var identifier = ""
    var location: CLLocationCoordinate2D?
    var date: Date?
    var asset: DKAsset?
    var dict: [String: Any] {
        return [
            "path": path,
            "thumbnail": thumbnail
        ]
    }
    
    // MARK: - Init
    init() {}
    
    init(asset: DKAsset) {        
        self.asset = asset
        self.identifier = asset.localIdentifier
        self.location = asset.location?.coordinate
        let dateStr = Styles.dateFormatter_HHmma.string(from: asset.originalAsset?.creationDate ?? Date())        
        self.date = Styles.dateFormatter_HHmma.date(from: dateStr)
    }
    
    init(path: String, thumbnail: String = "", identifier: String, location:CLLocationCoordinate2D?, date: Date?) {
        self.path = path
        self.thumbnail = thumbnail.isEmpty ? path : thumbnail
        self.identifier = identifier
        self.location = location
        self.date = date
    }
    
    init(path: String, thumbnail: String = "", identifier: String, location:CLLocationCoordinate2D?, date: Date?, asset: DKAsset) {
        self.path = path
        self.thumbnail = thumbnail.isEmpty ? path : thumbnail
        self.identifier = identifier
        self.location = location
        self.date = date
        self.asset = asset
    }
    
    init(data: [String : Any]) {        
        self.path = data["path"] as? String ?? ""
        self.thumbnail = data["thumbnail"] as? String ?? ""
        self.identifier = data["path"] as? String ?? ""
    }
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.path == rhs.path
    }
    
    
}
