//
//  Paging.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 7/11/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import Firebase
import RxCocoa
import RxSwift

let ITEM_PER_PAGE = 21

class Paging {
    // MARK: - Properties
    var start = 0 {
        didSet {
            if start == 0 {
                lastDocumentSnapshot = nil
                isMore.accept(true)
            }
        }
    }
    var itemPerPage = ITEM_PER_PAGE
    var isMore = BehaviorRelay<Bool>(value: true)
    var lastDocumentSnapshot: QueryDocumentSnapshot?
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init() {
        self.setup()
    }
    
    init(start: Int, itemPerPage: Int, isMore: Bool = true) {
        self.start = start
        self.itemPerPage = itemPerPage
        self.isMore.accept(isMore)
        self.setup()
    }
    
    func setup() {
        isMore.asObservable()
            .bind {[weak self] (isMore) in
                if !isMore {
                    self?.lastDocumentSnapshot = nil
                }
        }
        .disposed(by: disposeBag)
        
    }
}
