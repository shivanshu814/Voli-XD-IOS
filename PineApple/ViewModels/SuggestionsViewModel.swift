//
//  SuggestionsViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 30/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import CoreLocation
import FirebaseStorage

class SuggestionsViewModel: ViewModel {
    
    // MARK: - Properties
    enum SuggestionType: Int {
        case sameUser
        case similar
        case user
        case tag
        case image
        case followingUser
        case collection
        
        var title: String {
            switch self {
            case .sameUser: return "More from XXX"
            case .similar: return "Recommended for you"
            case .user: return "Recommended users"
            case .tag: return "Recommended tags"
            case .image: return "Recommended tags"
            case .followingUser: return "Following users"
            default: return ""
            }
        }
    }
    
    enum SimilarSubType: Int {
        case city
        case createDate
        
        var title: String {
            return "Recommended for you"
        }
    }
    
    enum UserSubType: Int {
        case city
        case popular
    }
    
    var savedCollection: SavedCollection?
    var itineraryViewModel: ItineraryViewModel?
    var profileViewModel: ProfileViewModel?
    var type: SuggestionType
    var isAll = false
    var suggestions = BehaviorRelay<[ItineraryDetailViewModel]>(value: [])
    var userSuggestions = BehaviorRelay<[UserCellViewModel]>(value: [])
    var tagSuggestions = BehaviorRelay<[TagCellViewModel]>(value: [])
    var tagViewModel: TagViewModel!
    let storage = Storage.storage()
    var paging = Paging()
    var isAnimated = true
    var tagIndex = 0
    var itemPerPage = ITEM_PER_PAGE
    var similarSubType = BehaviorRelay<SimilarSubType?>(value: nil)
    var userSubType = BehaviorRelay<UserSubType?>(value: nil)
    var title: String { return itineraryViewModel == nil && type == .tag ? "Related tags" : type.title }
        
    // MARK: - Init
    init(itineraryViewModel: ItineraryViewModel?, type: SuggestionType, subType: SimilarSubType? = nil, isAll: Bool = false) {
        self.itineraryViewModel = itineraryViewModel
        self.type = type
        self.isAll = isAll
        self.similarSubType.accept(subType)
        self.paging.itemPerPage = isAll ? ITEM_PER_PAGE : 4
        self.itemPerPage = paging.itemPerPage
    }
    
    init(profileViewModel: ProfileViewModel?, isAll: Bool = false) {
        self.profileViewModel = profileViewModel
        self.type = .followingUser
        self.isAll = isAll        
        self.paging.itemPerPage = isAll ? ITEM_PER_PAGE : 4
        self.itemPerPage = paging.itemPerPage
    }
    
    init(tagViewModel: TagViewModel) {
        self.tagViewModel = tagViewModel
        self.type = .image
        self.isAll = true
        self.itemPerPage = paging.itemPerPage
    }
    
    init(savedCollection: SavedCollection) {
        self.savedCollection = savedCollection
        self.type = .collection
        self.itemPerPage = paging.itemPerPage
        getSuggestion()
    }
    
}

// MARK: - Public
extension SuggestionsViewModel {
    
    func resetPaging() {
        paging.start = 0
        tagIndex = 0
        itemPerPage = ITEM_PER_PAGE
    }
    
    func getSuggestion(_ completionHandler: RequestDidCompleteBlock? = nil) {
        switch type {
        case .sameUser:
            if let id = itineraryViewModel?.user.value?.id, let itineraryId = itineraryViewModel?.model.id {
                Itinerary.findByUserId(id, filterId: itineraryId, paging: paging) {[weak self] (itineraries, error) in
                    guard let strongSelf = self else { return }
                    if error == nil {
                        if strongSelf.isAll {
                            let data = itineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                            strongSelf.handlePagingData(data, br: strongSelf.suggestions, paging: strongSelf.paging)
                            completionHandler?(true, nil)
                        } else {
                            strongSelf.suggestions.accept(itineraries.map{ItineraryDetailViewModel(itinerary: $0)})
                            completionHandler?(true, nil)
                        }
                    } else {
                        if strongSelf.isAll {
                            completionHandler?(false, error!)
                        }
                    }
                }
            }

        case .similar:
            
            func loadDataByCreateDate(_ completionHandler: RequestDidCompleteBlock? = nil) {
                similarSubType.accept(.createDate)
                
                if let itinerary = itineraryViewModel?.model {
                    let option = ItineraryFilterOption(location: "", state: "", country: "", tags: [], sortBy: .createDate)
                    Itinerary.find(by: option, filterId: itinerary.id, paging: paging) { [weak self]
                        (itineraries, error) in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            completionHandler?(false, error)
                        } else {
                            let data = itineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                            strongSelf.handlePagingData(data, br: strongSelf.suggestions, paging: strongSelf.paging)
                            completionHandler?(true, nil)
                        }
                    }
                }
            }
            
            func loadDataByCity(_ completionHandler: RequestDidCompleteBlock? = nil) {
                similarSubType.accept(.city)
                
                if let itinerary = itineraryViewModel?.model {
                    let option = ItineraryFilterOption(location: itinerary.city, state: itinerary.state, country: itinerary.country, tags: [], sortBy: .popularity)
                    Itinerary.find(by: option, filterId: itinerary.id, paging: paging) { [weak self]
                        (itineraries, error) in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            completionHandler?(false, error)
                        } else {
                            let data = itineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                            if data.isEmpty && strongSelf.suggestions.value.isEmpty {
                                // loadData by createdate
                                strongSelf.paging.start = 0
                                loadDataByCreateDate(completionHandler)
                            } else {
                                strongSelf.handlePagingData(data, br: strongSelf.suggestions, paging: strongSelf.paging)
                                completionHandler?(true, nil)
                            }
                        }
                    }
                }
            }
            
            func updateData(_ itineraries: [Itinerary]) {
                var newSuggestions = suggestions.value
                newSuggestions.append(contentsOf: itineraries.map{ItineraryDetailViewModel(itinerary: $0)})
                suggestions.accept(newSuggestions)
            }
            
            func loadData(_ completionHandler: RequestDidCompleteBlock? = nil) {
                if let itinerary = itineraryViewModel?.model {
                    let option = ItineraryFilterOption(location: itinerary.city, state: itinerary.state, country: itinerary.country, tags: itinerary.tags.isEmpty ? [] : [itinerary.tags[tagIndex]], sortBy: .popularity)
                    Itinerary.find(by: option, filterId: itinerary.id, paging: paging) { [weak self]
                        (itineraries, error) in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            completionHandler?(false, error)
                        } else {
                            // filter already fetched itineraries
                            var filteredItineraries = itineraries
                            strongSelf.suggestions.value.forEach {
                                filteredItineraries.removeObject($0.model.model)
                            }

                            if itineraries.count < strongSelf.paging.itemPerPage {
                                // not enough data
                                if strongSelf.tagIndex < itinerary.tags.count - 1 {
                                    // get data from next tag
                                    strongSelf.tagIndex += 1
                                    strongSelf.paging.start = 0
                                    // get until enough data or all tag is searched
                                    updateData(filteredItineraries)
                                    loadData(completionHandler)
                                    strongSelf.paging.isMore.accept(true)
                                } else {
                                    // no more similar data
                                    if strongSelf.suggestions.value.isEmpty {
                                        strongSelf.paging.start = 0
                                        loadDataByCity(completionHandler)
                                    } else {
                                        strongSelf.paging.isMore.accept(false)
                                        completionHandler?(true, nil)
                                    }
                                }
                            } else if filteredItineraries.count < strongSelf.paging.itemPerPage {
                                // not enough data after filtering
                                updateData(filteredItineraries)
                                loadData(completionHandler)
                                strongSelf.paging.isMore.accept(true)
                            } else {
                                // enough data
                                strongSelf.paging.isMore.accept(true)
                                updateData(filteredItineraries)
                                completionHandler?(true, nil)
                            }
                        }
                    }
                }
            }
               
            if similarSubType.value == nil {
                loadData(completionHandler)
            } else {
                switch similarSubType.value! {
                case .city: loadDataByCity(completionHandler)
                case .createDate: loadDataByCreateDate(completionHandler)
                }
            }
                        
        case .user:
            
            func loadPopularUser(_ completionHandler: RequestDidCompleteBlock? = nil) {
                userSubType.accept(.popular)
                
                User.findPopularUsers(paging) {[weak self] (users, error) in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        completionHandler?(false, error)
                    } else {
                        let data = users.map{UserCellViewModel(user: $0)}
                        strongSelf.handlePagingData(data, br: strongSelf.userSuggestions, paging: strongSelf.paging)
                        completionHandler?(true, nil)
                    }
                    
                }
            }
            
            func updateData(_ users: [User]) {
                var newSuggestions = userSuggestions.value
                newSuggestions.append(contentsOf: users.map{UserCellViewModel(user: $0)})
                userSuggestions.accept(newSuggestions)
            }
            
            func loadData(_ completionHandler: RequestDidCompleteBlock? = nil) {
                if let model = itineraryViewModel?.model {
                    User.findRecommendUserByCity(model.city, state: model.state, country: model.country, paging: paging) {[weak self] (users, error) in
                        guard let strongSelf = self else { return }
                        if error == nil {
                            // filter already fetched itineraries
                            var filteredUsers = users
                            strongSelf.userSuggestions.value.forEach {
                                filteredUsers.removeObject($0.user)
                            }

                            if users.count < strongSelf.paging.itemPerPage {
                                // not enough data
                                if strongSelf.userSuggestions.value.isEmpty {
                                    strongSelf.paging.start = 0
                                    loadPopularUser(completionHandler)
                                } else {
                                    strongSelf.paging.isMore.accept(false)
                                    completionHandler?(true, nil)
                                }
                            } else if filteredUsers.count < strongSelf.paging.itemPerPage {
                                // not enough data after filtering
                                updateData(filteredUsers)
                                loadData(completionHandler)
                                strongSelf.paging.isMore.accept(true)
                            } else {
                                // enough data
                                strongSelf.paging.isMore.accept(true)
                                updateData(filteredUsers)
                                completionHandler?(true, nil)
                            }

                        } else {
                            if strongSelf.isAll {
                                completionHandler?(false, error!)
                            }
                        }
                    }
                }
            }
            
            if userSubType.value == nil {
                loadData(completionHandler)
            } else {
                loadPopularUser(completionHandler)
            }
            
        case .tag:
            Tag.findFeaturedTags {[weak self] (tags, error) in
                if let error = error {
                    completionHandler?(false, error)
                } else {
                    self?.tagSuggestions.accept(tags.map{TagCellViewModel(tag: $0)})
                    completionHandler?(true, nil)
                }
            }
            
        case .image:
            tagViewModel.fetchTagActivities(completionHandler)
            
        case .followingUser:            
            User.getFollowingUser(profileViewModel?.model ?? Globals.currentUser!, paging: paging) {[weak self] (user, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    completionHandler?(false, error)
                } else {
                    if self?.profileViewModel?.model == nil {
                        Globals.currentUser = user
                    } else {
                        self?.profileViewModel?.setup(with: user)
                    }
                    
                    strongSelf.userSuggestions.accept(user.followingUsers.map{UserCellViewModel(user: $0)})
                    completionHandler?(true, nil)
                }
            }
            
        case .collection:
            if let savedCollection = savedCollection {
                suggestions.accept(savedCollection.itineraries)
            }
        }
        
    }
}
