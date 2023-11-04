//
//  CommentViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 8/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import FirebaseStorage

class CommentViewModel: ViewModel {
    private var _model: ItineraryDetailViewModel
    var model: ItineraryDetailViewModel { return _model }
    var newComment = BehaviorRelay<String>(value: "")
    var newTags = [String]()
    var comments = BehaviorRelay<[CommentCellViewModel]>(value: [])
    var users = [User]()
    var autocompleteUsers = BehaviorRelay<[User]>(value: [])
    private let disposeBag = DisposeBag()
    let storage = Storage.storage()
    var paging = Paging()
    
    // MARK: - Init
    init(model: ItineraryDetailViewModel) {
        self._model = model
        self.setup(with: _model)
    }
}

// MARK: - ViewModel
extension CommentViewModel {
    
    func setup(with model: ItineraryDetailViewModel) {
        _model = model
        
        comments
            .asObservable()
            .bind {[weak self] (comments) in
                guard let strongSelf = self else { return }
                strongSelf.users = []
                comments.forEach {
                    if !strongSelf.users.contains($0.model.user) {
                        strongSelf.users.append($0.model.user)
                    }
                }
            }
            .disposed(by: disposeBag)
    }
    
}

// MARK - Public
extension CommentViewModel {
    
    func refresh(_ comment: Comment) {
        if let index = (comments.value.map{$0.model}).firstIndex(of: comment) {
            comments.value[index].setup(with: comment, itinerary: model.itinerary)
        }
    }
        
    func fetchComments(_ completionHandler: @escaping RequestDidCompleteBlock) {
        
        Itinerary.findComments(model.itinerary, paging: paging) {[weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completionHandler(false, error)
            } else {
                let newComments = result.map{CommentCellViewModel(model: $0, itinerary: strongSelf.model.itinerary)}
                
                for i in 0..<newComments.count {
                    let id = newComments[i].itinerary.id + "_" + newComments[i].model.id
                    newComments[i].isLike.accept(Globals.currentUser?.likedComments.contains(id) ?? false)
                }
                strongSelf.handlePagingData(newComments, br: strongSelf.comments, paging: strongSelf.paging)
                completionHandler(true, nil)
            }
        }                
    }
    
    func postComment(_ comment: Comment, completionHandler: @escaping RequestDidCompleteBlock) {
        var itinerary = _model.model.model
        
        let createComment = {
            Itinerary.createComment(itinerary, comment: comment) {[weak self] (id, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    completionHandler(false, error)
                } else {
                    var newComments = strongSelf.comments.value
                    var newComment = comment
                    newComment.id = id
                    newComments.insert(CommentCellViewModel(model:newComment, itinerary: strongSelf.model.itinerary), at: 0)
                    strongSelf.comments.accept(newComments)
                    strongSelf.newComment.accept("")
                    strongSelf.newTags = []
                    completionHandler(true, nil)
                }
            }
        }
        if itinerary.user.email.isEmpty {
            User.findById(itinerary.user.id) { (user, error) in
                if let user = user {
                    itinerary.user = user
                }
                createComment()
            }
        } else {
            createComment()
        }
        
    }    
}
