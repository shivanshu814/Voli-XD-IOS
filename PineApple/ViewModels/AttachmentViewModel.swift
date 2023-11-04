//
//  AttachmentViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseStorage

class AttachmentViewModel: ViewModel {
    
    // MARK: - Properties
    var attachment: Attachment
    var indexPath: IndexPath?
    var heroPrefix: String
    let storage = Storage.storage()
    
    // MARK: - Init
    init(attachment: Attachment, indexPath: IndexPath? = nil, heroPrefix: String = "Detail") {
        self.attachment = attachment
        self.indexPath = indexPath
        self.heroPrefix = heroPrefix
    }

}

// MARK: - Equatable
extension AttachmentViewModel: Equatable {
    static func == (lhs: AttachmentViewModel, rhs: AttachmentViewModel) -> Bool {
        return lhs.attachment == rhs.attachment
    }
}
