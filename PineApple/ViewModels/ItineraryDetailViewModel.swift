//
//  ItineraryDetailViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import FirebaseStorage

class ItineraryDetailViewModel: ViewModel {
    
    // MARK: - Properties
    private var _model: ItineraryViewModel
    var model: ItineraryViewModel { return _model }
    var timeSpend = BehaviorRelay<String>(value: "")
    var cityDuration = BehaviorRelay<String>(value: "")
    var city = BehaviorRelay<String>(value: "")
    var userName = BehaviorRelay<String>(value: "")
    var numberOfItinerary = BehaviorRelay<String>(value: "")
    var showContact = BehaviorRelay<Bool>(value: false)
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var attachments = BehaviorRelay<[AttachmentViewModel]>(value: [])
    var heroImage = BehaviorRelay<StorageReference?>(value: nil)
    var comment = BehaviorRelay<Comment?>(value: nil)
    var sameUserSuggestion: SuggestionsViewModel!
    var similarSuggestion: SuggestionsViewModel!
    var recommendedUsers: SuggestionsViewModel!
    var recommendedTags: SuggestionsViewModel!
    let storage = Storage.storage()
    var rows = BehaviorRelay<[ViewModel]>(value: [])
    var heroPrefix = "Detail"
    var indexPath: IndexPath?
    var itinerary: Itinerary { return model.model }
    var isOwner: Bool { return Globals.currentUser == itinerary.user }
    var collection: SavedCollection?
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(itinerary: ItineraryViewModel) {
        self._model = itinerary
        self.setup(with: itinerary)
    }
    
    // MARK: - Init
    init(itinerary: Itinerary) {
        self._model = ItineraryViewModel(itinerary: itinerary)
        self.setup(with: _model)
    }
    
    // MARK: - Init
    init(id: String) {
        self._model = ItineraryViewModel(id: id)
        recommendedTags = SuggestionsViewModel(itineraryViewModel: model, type: .tag)
    }
}

// MARK: - ViewModel
extension ItineraryDetailViewModel {
    
    func setup(with model: ItineraryViewModel) {
        _model = model
                
        // Sum up all activity's time spend
        let duration = model.activityViewModels.reduce(0) { (result, activityViewModel) -> Int in
            result + activityViewModel.timeSpend.value.int
        }
        timeSpend.accept(TimeInterval(exactly: duration)?.toShortString ?? "")
                
        userName.accept("By: \(model.user.value?.displayName ?? "")")
        cityDuration.accept("City: \(model.model.city.capitalized) | Duration: \(timeSpend.value)")
        
        let fullName = model.model.country == "hong kong" ? model.model.country : "\(model.model.city.isEmpty ? "" : "\(model.model.city), ")\(model.model.state.isEmpty ? "": "\(model.model.state), ")\(model.model.country)"
        city.accept(fullName.capitalized)
        // Group all activity's tag and attachment
        var allTags = [TagCellViewModel]()
        var allAttachments = [AttachmentViewModel]()
        model.activityViewModels.forEach {
            for tag in $0.tags.value {
                if !allTags.contains(tag) {
                    allTags.append(tag)
                }
            }
            
            for attachment in $0.attachments.value {
                allAttachments.append(attachment)
            }
        }
        if let heroIndex = (allAttachments.map{$0.attachment.path}).firstIndex(of: model.heroImage.value) {
            let attachment = allAttachments[heroIndex]
            allAttachments.remove(at: heroIndex)
            allAttachments.insert(attachment, at: 0)
        }
        
        tags.accept(allTags)
        
        if !itinerary.coverVideo.isEmpty {
            let attachment = Attachment(path: itinerary.coverVideo, thumbnail: itinerary.heroImageThumbnail, identifier: coverVideo, location: nil, date: nil)
            allAttachments.insert(AttachmentViewModel(attachment: attachment), at: 0)
        }
        attachments.accept(allAttachments)
        
        if let path = allAttachments.first?.attachment.path {
            let storageRef = storage.reference()
            heroImage.accept(storageRef.child(path))
        }
        
        // Rows
        var _rows = [ViewModel]()
        _rows.append(model) // header
        _rows.append(contentsOf: model.activityViewModels) // activities
        _rows.append(model) // footer
        
        if sameUserSuggestion == nil {
            sameUserSuggestion = SuggestionsViewModel(itineraryViewModel: model, type: .sameUser)
            
            if !isOwner {
                sameUserSuggestion.suggestions
                    .asObservable()
                    .bind {[weak self] (suggestions) in
                        guard let strongSelf = self else { return }
                        if !suggestions.isEmpty {
                            var newRow = strongSelf.rows.value
                            newRow.insert(strongSelf.sameUserSuggestion, at: newRow.count-2)
                            strongSelf.rows.accept(newRow)
                        }
                }.disposed(by: disposeBag)
            }
            
        }
        if similarSuggestion == nil {
            similarSuggestion = SuggestionsViewModel(itineraryViewModel: model, type: .similar)
        }
        _rows.append(similarSuggestion) // similar
        
        if recommendedUsers == nil {
            recommendedUsers = SuggestionsViewModel(itineraryViewModel: model, type: .user)
        }
        if recommendedTags == nil {
            recommendedTags = SuggestionsViewModel(itineraryViewModel: model, type: .tag)
        }
        
        _rows.append(recommendedUsers) // same user
        
        rows.accept(_rows)
    }
}

// MARK - Public
extension ItineraryDetailViewModel {
    
    func loadData(_ completionHandler: @escaping RequestDidCompleteBlock) {
                
        func fetchSuggestion() {
            if model.user.value != nil {
                sameUserSuggestion.resetPaging()
                similarSuggestion.resetPaging()
                recommendedUsers.resetPaging()
                recommendedTags.resetPaging()
                
                if !isOwner {
                    sameUserSuggestion.getSuggestion()                    
                }
                similarSuggestion.getSuggestion()
                recommendedUsers.getSuggestion()
                recommendedTags.getSuggestion()
            }
        }
        
        model.fetch {[weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completionHandler(false, error)
            } else {     
                self?.setup(with: strongSelf.model)
                self?.getUser()
                self?.getFirstComment()
                fetchSuggestion()
                completionHandler(true, nil)
            }
        }
        
    }
            
    func downloadImage(_ url: String) {
        let storageRef = storage.reference()
        heroImage.accept(storageRef.child(url))
    }
    
    func like() {
        guard Globals.currentUser != nil else { return }
        
        func handleLikeRequest(error: Error?) {
            if let error = error {
                // Rollback if failure
                _model.isLike.accept(!_model.isLike.value)
                _model.likeCount.accept(_model.isLike.value ? _model.likeCount.value + 1 : _model.likeCount.value - 1)
                               
                Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
                
        _model.isLike.accept(!_model.isLike.value)
        _model.likeCount.accept(_model.isLike.value ? _model.likeCount.value + 1 : _model.likeCount.value - 1)
        
        if _model.isLike.value {
            if itinerary.user.email.isEmpty {
                User.findById(itinerary.user.id) {[weak self] (user, error) in
                    guard let strongSelf = self else { return }
                    if let user = user {
                        var itinerary = strongSelf.itinerary
                        itinerary.user = user
                        strongSelf.model.setModel(itinerary)
                    }
                    User.addLikedItinerary(strongSelf.itinerary) { (result, error) in
                        handleLikeRequest(error: error)
                    }
                }
            } else {
                User.addLikedItinerary(_model.model) { (result, error) in
                    handleLikeRequest(error: error)
                }
            }
        } else {
            User.removeLikedItinerary(_model.model) { (result, error) in
                handleLikeRequest(error: error)
            }
        }
        
    }
    
    func save(_ completionHandler: RequestDidCompleteBlock) {
        guard Globals.currentUser != nil else { return }
        model.isSave.accept(!model.isSave.value)
        model.savedCount.accept(model.savedCount.value+1)
        completionHandler(true, nil)
    }
    
    func unsave(_ completionHandler: @escaping RequestDidCompleteBlock) {
        guard Globals.currentUser != nil else { return }
        model.isSave.accept(!model.isSave.value)
        model.savedCount.accept(model.savedCount.value-1)
        if collection == nil || (collection!.name.isEmpty && collection!.itineraries.isEmpty) {
            let keys = Globals.currentUser!.savedItineraries.map{$0.keys.first!}
            if let index = keys.firstIndex(of: itinerary.id) {
                let info = Globals.currentUser!.savedItineraries[index]
                if let cid = info[itinerary.id] {
                    collection = SavedCollection(id: cid, name: "", itineraries: [])
                }
            }
        }
                
        if let _collection = collection {
            
            SavedCollection.findItineraries(in: _collection, paging: Paging(start: 0, itemPerPage: 4)) {[weak self] (itineraries, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    print("Error writing document: \(error)")
                    completionHandler(false, error)
                } else {
                    var newSavedCollection = _collection
                    var newItineraries = (itineraries.filter{$0 != strongSelf.itinerary})
                    if newItineraries.isEmpty {
                        // delete collection
                        SavedCollection.delete(newSavedCollection, itineraries: itineraries) {[weak self] (result, error) in
                            guard let strongSelf = self else { return }
                            if error != nil {
                                strongSelf.model.isSave.accept(!strongSelf.model.isSave.value)
                            }
                            completionHandler(true, nil)
                        }
                        return
                    } else if newItineraries.count > 3 {
                        newItineraries = newItineraries[0..<3].map{$0}
                    }
                    newSavedCollection.itineraries = newItineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                    SavedCollection.remove(itinerary: strongSelf.itinerary, from: newSavedCollection) { [weak self] (result, error) in
                        guard let strongSelf = self else { return }
                        if error != nil {
                            strongSelf.model.isSave.accept(!strongSelf.model.isSave.value)
                        }
                        completionHandler(true, nil)
                    }
                }
            }
        }
    }
    
    func getFirstComment() {
        Itinerary.findComments(itinerary, paging: Paging(start: 0, itemPerPage: 1)) {[weak self] (result, error) in
            guard let strongSelf = self else { return }
            if error == nil{
                strongSelf.comment.accept(result.first)
            }
        }
    }
    
    func getUser() {
        User.findById(itinerary.user.id) {[weak self](user, error) in
            if let user = user {
                let suffix = user.itineraryCount > 1 ? " itineraries" : " itinerary"
                self?.numberOfItinerary.accept(String(user.itineraryCount) + suffix)
                
                if user.isPrivate {
                    if let currentUser = Globals.currentUser,!currentUser.followingUserIds.contains(user.id) {
                        User.getFollowingUserId(user) {[weak self] (ids, error) in
                            self?.showContact.accept(ids.contains(currentUser.id))
                        }
                    } 
                } else {
                    self?.showContact.accept(true)
                }
            }
        }
    }
}

// MARK - Equatable
extension ItineraryDetailViewModel: Equatable {
    static func == (lhs: ItineraryDetailViewModel, rhs: ItineraryDetailViewModel) -> Bool {
        return lhs.model.model.id == rhs.model.model.id
    }
}
