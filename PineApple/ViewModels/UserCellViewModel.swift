//
//  RecommendedUserViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import FirebaseStorage

class UserCellViewModel: ViewModel {
    
    // MARK: - Properties
    var user: User
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var nameLocation = BehaviorRelay<String>(value: "")
    var itineraryCount = BehaviorRelay<String>(value: "")
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)
    var name = BehaviorRelay<String>(value: "")
    var location = BehaviorRelay<String>(value: "")
    var hideFollowView = BehaviorRelay<Bool>(value: false)
    var isFollowing = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(user: User) {
        self.user = user
        setup(with: user)
    }
}

// MARK: - ViewModel
extension UserCellViewModel {
    func setup() {
        setup(with: user)
    }
    
    func setup(with model: User) {
        isFollowing.accept(Globals.currentUser?.followingUserIds.contains(user.id) ?? false)
        name.accept(user.displayName)
        location.accept(user.location)
        if Globals.currentUser == nil {
            hideFollowView.accept(true)
        } else {
            hideFollowView.accept(!Globals.currentUser!.followingUsers.contains(user))
        }
                
        tags.accept(user.tags.map{TagCellViewModel(tag: $0)})
        nameLocation.accept("\(user.displayName), \(user.city.capitalized)")
        itineraryCount.accept("\(user.itineraryCount) \(user.itineraryCount > 0 ? "itineraries" : "itinerary" )")
        
        let storageRef = Storage.storage().reference()
        profileImage.accept(storageRef.child(user.thumbnail))
    }
    
    private func updateModel() {
        
    }
}

// MARK: - Public
extension UserCellViewModel {
    func follow() {
        guard Globals.currentUser != nil else { return }
        
        func handleLikeRequest(error: Error?) {
            if let error = error {
                // Rollback if failure
                isFollowing.accept(!isFollowing.value)
                Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
                
        isFollowing.accept(!isFollowing.value)
        
        if isFollowing.value {
            User.followUser(user) { (_, error) in
                handleLikeRequest(error: error)
            }
        } else {
            User.unfollowUser(user) { (_, error) in
                handleLikeRequest(error: error)
            }
            
        }
    }
}
