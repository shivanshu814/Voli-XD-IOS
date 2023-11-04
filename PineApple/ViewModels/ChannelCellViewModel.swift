//
//  ChannelCellViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 21/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import FirebaseUI

class ChannelCellViewModel: ViewModel {
    
    // MARK: - Properties
    private var _model: ATCChatChannel
    var model: ATCChatChannel { return _model }
    var name = BehaviorRelay<String>(value: "")
    var unreadCount = BehaviorRelay<Int>(value: 0)
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)
    var message = BehaviorRelay<String>(value: "")
    var date = BehaviorRelay<String>(value: "")
    var isFollowing = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(model: ATCChatChannel) {
        self._model = model
        self.setup(with: model)
    }
}

// MARK: - ViewModel
extension ChannelCellViewModel {
    func setup(with model: ATCChatChannel) {
        if let user = (model.users.filter{$0 != Globals.currentUser!}).first {
            name.accept(user.displayName)
            unreadCount.accept(model.userIndex == 1 ? model.unreadCount1 : model.unreadCount2)
            let storageRef = Storage.storage().reference()
            profileImage.accept(storageRef.child(user.thumbnail))
            message.accept(model.lastMessage)
            
            date.accept(model.lastUpdated.toDateTimeString)
            isFollowing.accept(Globals.currentUser!.followingUserIds.contains(user.id))
        }
        
    }
}
