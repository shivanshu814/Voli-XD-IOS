//
//  ProfileDetailViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 13/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import FirebaseStorage
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileDetailViewModel: ViewModel {
    
    // MARK: - Properties
    private var _model: ProfileViewModel
    var model: ProfileViewModel { return _model }
    var isEditing = BehaviorRelay<Bool>(value: true)
    var isInterestsEditing = BehaviorRelay<Bool>(value: false)
    var isAboutEditing = BehaviorRelay<Bool>(value: false)
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)
    var name = BehaviorRelay<String>(value: "")
    var location = BehaviorRelay<String>(value: "")
    var numberOfItinerary = BehaviorRelay<String>(value: "")
    var isOwner = BehaviorRelay<Bool>(value: false)
    var follower = BehaviorRelay<String>(value: "")
    var following = BehaviorRelay<String>(value: "")
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var about = BehaviorRelay<String>(value: "")
    var followingUsers = BehaviorRelay<[User]>(value: [])
    var itineraries = BehaviorRelay<[ItineraryDetailViewModel]>(value: [])
    let storage = Storage.storage()
    var rows = BehaviorRelay<[Any]>(value: [1,3])
    var isFollowing = BehaviorRelay<Bool?>(value: nil)
    var paging = Paging()
    var isAnimated = true
    var user: User? {
        return model.model
    }
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(model: ProfileViewModel) {
        _model = model
        setup(with: model)
    }
    
    init(user: User) {
        _model = ProfileViewModel(model: user)
        setup(with: _model)
    }
    
    init(id: String) {
        _model = ProfileViewModel(id: id)
    }
}

// MARK: - ViewModel
extension ProfileDetailViewModel {
    func setup(with model: ProfileViewModel) {
        _model = model
        if let _user = model.model {
            let storageRef = Storage.storage().reference()
            profileImage.accept(storageRef.child(_user.thumbnail))
            name.accept(_user.displayName)
            location.accept(_user.location)
            numberOfItinerary.accept(String(_user.itineraryCount))
            follower.accept(_user.followerCount.shorted())
            following.accept(_user.followingCount.shorted())
            tags.accept(_user.tags.map{TagCellViewModel(tag: $0)})
            about.accept(_user.about)
            isOwner.accept(_user == Globals.currentUser)
        }
        
        if isAnimated {
            itineraries
                .asObservable()
                .bind {[weak self] (itineraries) in
                    guard let strongSelf = self else { return }
                    if strongSelf.user?.location == nil || strongSelf.isAnimated {
                        return
                    }
                    strongSelf.updateRows()
            }
            .disposed(by: disposeBag)
        }
        
    }
    
    private func updateModel() {
        _model.updateAbout(about.value)
        _model.updateTags(tags.value.map{$0.tag.name})
    }
}


// MARK: - Public
extension ProfileDetailViewModel {
    
    func refresh(_ itinerary: Itinerary) {
        if let index = (itineraries.value.map{$0.itinerary}).firstIndex(of: itinerary) {
            if (user != Globals.currentUser && itinerary.isPrivate) || itinerary.isDeleted {
                var newRow = itineraries.value
                newRow.remove(at: index)
                itineraries.accept(newRow)
            } else {
                let model = itineraries.value[index].model
                model.setup(with: itinerary)
                itineraries.value[index].setup(with: model)
            }            
        }
    }
    
    func updateRows() {
        var newRows: [Any] = [1,3]
        if !followingUsers.value.isEmpty {
            newRows.insert(2, at: 1)
        }
        newRows.append(contentsOf: itineraries.value)
        rows.accept(newRows)
    }
    
    func updateTags(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        model.saveTags(completionHandler)
    }
    
    func updateAbout(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        model.saveAbout(completionHandler)
    }
    
    func updateProfile(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        model.save(completionHandler)
    }
    
    func fetchUserProfile(_ completionHandler: @escaping RequestDidCompleteBlock) {
        
        func updateModelIfNeeded(_ model: ProfileViewModel) {
            if user?.location != nil {
                setup(with: model)
            }
        }
        
        func findById(_ completionHandler: @escaping RequestDidCompleteBlock) {
            User.findById(model.model!.id) {(user, error) in
                if let error = error {
                    completionHandler(false, error)
                } else {
                    updateModelIfNeeded(ProfileViewModel(model: user))
                    completionHandler(true, nil)
                }
            }
        }
        
        updateModelIfNeeded(model)
        if let user = Auth.auth().currentUser, (user.isAnonymous || model.model == Globals.currentUser) {
            findById(completionHandler)
        } else {
            checkIfFollowing {(result, error) in
                findById(completionHandler)
            }
        }
                
        fetchFollowingUser()
    }
    
    func checkIfFollowing(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if let user = model.model {
            isFollowing.accept(Globals.currentUser?.followingUserIds.contains(user.id) ?? false)
            completionHandler(true, nil)
        }
    }
    
    func follow() {
        guard Globals.currentUser != nil else { return }
        
        func handleLikeRequest(error: Error?) {
            if let error = error {
                // Rollback if failure
                isFollowing.accept(!(isFollowing.value ?? false))
                follower.accept(String(isFollowing.value ?? false ? Int(follower.value)! + 1 : Int(follower.value)! - 1))
                               
                Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
                
        isFollowing.accept(!(isFollowing.value ?? false))
        follower.accept(String(isFollowing.value ?? false ? Int(follower.value)! + 1 : Int(follower.value)! - 1))
        
        if let user = model.model {
            if isFollowing.value ?? false {
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
    
    func fetchFollowingUser(_ completionHandler: RequestDidCompleteBlock? = nil) {
        if let user = model.model {
            
            let paging = Paging()
            User.getFollowingUser(user, paging: paging) {[weak self] (user, error) in
                guard let strongSelf = self else { return }
                strongSelf.followingUsers.accept(user.followingUsers)
                strongSelf.updateRows()
            }
        }
        
    }
    
    func fetchMyItineraries(_ completionHandler: RequestDidCompleteBlock? = nil) {
        
        Itinerary.findByUserId(user!.id, paging: paging) {[weak self] (itineraries, error) in
            guard let strongSelf = self else { return }
            if error == nil{
                var newItineraries = itineraries
                for i in 0..<newItineraries.count {
                    newItineraries[i].updateLikeCommentSave()
                }
                let data = newItineraries.map{ItineraryDetailViewModel(itinerary: $0)}                
                strongSelf.handlePagingData(data, br: strongSelf.itineraries, paging: strongSelf.paging)
                completionHandler?(true, nil)
            } else {
                completionHandler?(false, error)
            }
        }        
    }
    
    func deleteTag(_ tag: TagCellViewModel) {
        var newTags = tags.value
        newTags.removeObject(tag)
        tags.accept(newTags)
    }
    
    func reportAbuse(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if let user = user {
            User.reportAbuse(user, completionHandler: completionHandler)
        }
    }
    
    static func logout() {
        let firebaseAuth = Auth.auth()
        do {
            Globals.currentUser = nil
            try firebaseAuth.signOut()
            LoginManager().logOut()
            GIDSignIn.sharedInstance()?.signOut()
            ProfileDetailViewModel.anonymousLoginIfNeeded()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    static func anonymousLoginIfNeeded() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously() { (authResult, error) in
                if error != nil {
                    Globals.topViewController.showAlert(title: "Error", message: error!.localizedDescription)
                } else {
                    NotificationCenter.default.post(name: .didLogin, object: nil)
                }
            }
        } else if Auth.auth().currentUser!.isAnonymous {
            NotificationCenter.default.post(name: .didLogin, object: nil)
        } else {
            if Globals.currentUser == nil {
                User.currentUser ({ (result, error) in
                    PushNotificationManager.shared.registerForPushNotifications()
                    
                })
            }
            
        }
        
    }
}
