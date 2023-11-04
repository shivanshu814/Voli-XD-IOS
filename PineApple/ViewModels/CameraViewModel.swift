//
//  CameraViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AVKit

class CameraViewModel: ViewModel {
    // MARK: - Properties
    var activityViewModel: ActivityViewModel?
    var profileViewModel: ProfileViewModel?
    var attachments = BehaviorRelay<[Attachment]>(value: [])
    var paths = BehaviorRelay<(path: String, thumbnail: String)?>(value: nil)
    var showPreviewImage = BehaviorRelay<Bool>(value: false)
    var isUploadProfile: Bool {
        return profileViewModel != nil
    }
    var isSingleUpload: Bool {
        return activityViewModel == nil && profileViewModel == nil
    }
    var isShowingPreview = false
    var isVideo = false
    var avAsset: AVURLAsset?
    var currentPath: (path: String, thumbnail: String)?
    
    // MARK: - Init
    init() {}
    
    init(activityViewModel: ActivityViewModel) {
        self.activityViewModel = activityViewModel
    }
    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
    }
}
