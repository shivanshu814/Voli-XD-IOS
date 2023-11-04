//
//  TagCollectionViewCell.swift
//  NBCU
//
//  Created by Steven Tao on 6/9/2016.
//  Copyright © 2016 ROKO. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TagCollectionViewCell: UICollectionViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagLabelLeading: NSLayoutConstraint!
    @IBOutlet weak var tagLabelTrailing: NSLayoutConstraint!
    
    var viewModel: TagCellViewModel!
    private var disposeBag = DisposeBag()
    var cellSize: CGSize {
        let size = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return size
    }
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForReuse() {
        setup()
        disposeBag = DisposeBag()
    }
    
    func setup() {
        tagLabel.font = Styles.customFont(15)
        borderColor = Styles.pCFC2FF
        borderWidth = 0
        backgroundColor = Styles.pF6F2FE
        tagLabel.textColor = Styles.g504F4F
        tagLabelLeading.constant = 16
        tagLabelTrailing.constant = 16
        cornerRadius = 15
    }
}


// MARK: - RX
extension TagCollectionViewCell {
    
    func bindViewModel(_ viewModel: TagCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.name
            .asDriver()
            .drive(tagLabel.rx.text)
            .disposed(by: disposeBag)
        
        if viewModel.isSelectionEnabled {
            viewModel.isSelected
                .asObservable()
                .bind {[weak self] (isSelected) in
                    guard let strongSelf = self else { return }
                    if isSelected {
                        strongSelf.backgroundColor = Styles.p8437FF
                        strongSelf.tagLabel.textColor = UIColor.white
                        strongSelf.borderWidth = 0
                    } else {
                        strongSelf.backgroundColor = UIColor.clear
                        strongSelf.tagLabel.textColor = Styles.g504F4F
                        strongSelf.borderWidth = 1
                    }
                }
                .disposed(by: disposeBag)
        }
    }
    
}

// MARK: - Public
extension TagCollectionViewCell {
    // MARK: - View Life Cycle
    func enableNoBoarderStyle() {
        cornerRadius = 0
        tagLabel.font = Styles.customFontLight(13)
        tagLabelLeading.constant = 0
        tagLabelTrailing.constant = 0
        backgroundColor = UIColor.clear
        tagLabel.textColor = Styles.g797979
    }
}
