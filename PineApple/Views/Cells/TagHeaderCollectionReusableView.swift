//
//  TagHeaderCollectionReusableView.swift
//  PineApple
//
//  Created by Tao Man Kit on 11/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TagHeaderCollectionReusableView: UICollectionReusableView {
    
    // MARK: - Properties    
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var sortButton: UIButton!
    var viewModel: String!
    typealias SortButtonDidClickBlock = () -> Void
    var sortButtonDidClickBlock: SortButtonDidClickBlock?
    private var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
    
}

// MARK: - RX
extension TagHeaderCollectionReusableView {
    
    func bindViewModel(_ viewModel: String) {
        self.viewModel = viewModel
        
        tagLabel.text = viewModel
        
        bindAction()
    }
    
    func bindAction() {
        sortButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.sortButtonDidClickBlock?()
            }.disposed(by: disposeBag)
    }
}
