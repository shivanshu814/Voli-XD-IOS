//
//  CommentCellViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 8/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import FirebaseStorage

class CommentCellViewModel: ViewModel {
    
    // MARK: - Properties
    private var _model: Comment
    var model: Comment { return _model }
    var itinerary: Itinerary
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)
    var name = BehaviorRelay<String>(value: "")
    var message = BehaviorRelay<String>(value: "")
    var createDate = BehaviorRelay<Date>(value: Date())
    var likeCount = BehaviorRelay<Int>(value: 0)
    var isLike = BehaviorRelay<Bool>(value: true)
    private let disposeBag = DisposeBag()
    let storage = Storage.storage()
    
    // MARK: - Init
    init(model: Comment, itinerary: Itinerary) {
        self._model = model
        self.itinerary = itinerary
        setup(with: model, itinerary: itinerary)
    }
    
}

// MARK: - ViewModel
extension CommentCellViewModel {
    
    func setup(with model: Comment, itinerary: Itinerary) {        
        let storageRef = storage.reference()
        profileImage.accept(storageRef.child(model.user.thumbnail))
        name.accept(model.user.displayName)
        message.accept(model.message)
        createDate.accept(model.date)
        likeCount.accept(model.likeCount)
        isLike.accept(model.isLike)

    }
}

// MARK - Public
extension CommentCellViewModel {
    
    func like() {
        guard Globals.currentUser != nil else { return }
        
        func handleLikeRequest(error: Error?) {
            if let error = error {
                isLike.accept(!isLike.value)
                likeCount.accept(isLike.value ? likeCount.value + 1 : likeCount.value - 1)
                               
                Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
                
        isLike.accept(!isLike.value)
        likeCount.accept(isLike.value ? likeCount.value + 1 : likeCount.value - 1)
        
        if isLike.value {
            User.addLikedComment(model, itinerary: itinerary, completionHandler: { (result, error) in
                handleLikeRequest(error: error)
            })
        } else {
            User.removeLikedComment(model, itinerary: itinerary, completionHandler: { (result, error) in
                handleLikeRequest(error: error)
            })
        }
        
    }
    
}

extension CommentCellViewModel: Equatable {
    
    static func == (lhs: CommentCellViewModel, rhs: CommentCellViewModel) -> Bool {
        return lhs.model.id == rhs.model.id
    }
    
}
