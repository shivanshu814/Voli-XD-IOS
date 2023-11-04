//
//  TagCellViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TagCellViewModel: ViewModel {
    
    // MARK: - Properties    
    var tag: Tag
    var name = BehaviorRelay<String>(value: "")
    var count = BehaviorRelay<String>(value: "")
    var isSelected = BehaviorRelay<Bool>(value: false)
    var isSelectionEnabled = false    
    
    // MARK: - Init
    init(tag: Tag, isSelectionEnabled: Bool = false) {
        self.tag = tag
        self.isSelectionEnabled = isSelectionEnabled
        name.accept(tag.name)
        count.accept("\(tag.taggedCount) \(tag.taggedCount <= 1 ? "itinerary" : "itineraries")")
    }
    
    init(tag: String, isSelectionEnabled: Bool = false) {
        self.tag = Tag(name: tag, taggedCount: 0)
        self.isSelectionEnabled = isSelectionEnabled
        name.accept(self.tag.name)
        count.accept("\(self.tag.taggedCount) \(self.tag.taggedCount <= 1 ? "itinerary" : "itineraries")")
    }
    
}

// MARK: - Public
extension TagCellViewModel {
    func showPrefix() {
        name.accept("#" + tag.name)
    }
    
    func removePrefix() {
        name.accept(tag.name)
    }
}

// MARK: - Equatable
extension TagCellViewModel: Equatable{
    static func == (lhs: TagCellViewModel, rhs: TagCellViewModel) -> Bool {
        return lhs.tag.name == rhs.tag.name
    }
}
