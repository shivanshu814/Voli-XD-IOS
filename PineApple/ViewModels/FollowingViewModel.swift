//
//  FollowingViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 27/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class FollowingViewModel: ViewModel {
    private var _model: User?
    var model: User? { return _model }
    var followingUsers = BehaviorRelay<[UserCellViewModel]>(value: [])
    var searchText = BehaviorRelay<String>(value: "")
    var mode = UserTableViewCell.Mode.message
    var shareTitle: String?
    var shareType: String?
    var shareLink: URL?
    var paging = Paging()
    var searchPaging = Paging(start: 0, itemPerPage: 20)
    var isAnimated = true
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(model: User?, mode: UserTableViewCell.Mode = .message, shareLink: URL? = nil, shareTitle: String? = nil, shareType: String? = nil) {
        self._model = model
        self.mode = mode
        self.shareLink = shareLink
        self.shareTitle = shareTitle
        self.shareType = shareType
        setup(with: model)
    }
}

// MARK: - ViewModel
extension FollowingViewModel {
    func setup(with model: User?) {
        _model = model
        followingUsers.accept(model?.followingUsers.map{UserCellViewModel(user: $0)} ?? [])
    }
    
    private func updateModel() {
        _model?.followingUsers = followingUsers.value.map{$0.user}
    }
}

// MARK: - Public
extension FollowingViewModel {
    func getFollowingUser(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = _model {
            
            User.getFollowingUser(currentUser, paging: paging) {[weak self] (user, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    completionHandler(false, error)
                } else {
                    strongSelf._model = user
                    let data = user.followingUsers.map{UserCellViewModel(user: $0)}
                    strongSelf.followingUsers.accept(data)
                    completionHandler(true, nil)
                }
            }
        } else {
            followingUsers.accept([])
        }
    }
    
    func filterUser(keyword: String, completionHandler: RequestDidCompleteBlock? = nil) {
        if keyword.isEmpty {
            followingUsers.accept(_model?.followingUsers.map{UserCellViewModel(user: $0)} ?? [])
        } else {
            if let currentUser = _model {
                User.findFollowingUser(currentUser, searchName: keyword.lowercased(), paging: searchPaging) {[weak self] (users, error) in
                    guard let strongSelf = self else { return }
                    if strongSelf.searchText.value == keyword.lowercased() {
                        if let error = error {
                            print(error.localizedDescription)
                            completionHandler?(false, error)
                        } else {
                            let data = users
                                .filter{$0.displayName.lowercased().starts(with: keyword.lowercased())}
                                .map{UserCellViewModel(user: $0)}
                            strongSelf.followingUsers.accept(data)                            
                            completionHandler?(true, nil)
                        }
                        
                    }
                }
            }
        }
    }
    
    
}
