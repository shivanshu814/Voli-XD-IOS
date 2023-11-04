//
//  RecommendedTagTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class RecommendedTagTableViewCell: UITableViewCell {

    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    var sizingCell: TagCollectionViewCell!
    @IBOutlet weak var tagCollectionViewHeight: NSLayoutConstraint!
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    typealias SeeAllDidClickBlock = (SuggestionsViewModel) -> Void
    var seeAllDidClickBlock: SeeAllDidClickBlock?
    typealias TagDidClickBlock = (String) -> Void
    var tagDidClickBlock: TagDidClickBlock?
    var viewModel: SuggestionsViewModel!
    private var disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTagCollectionView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
}

// MARK: - RX
extension RecommendedTagTableViewCell {
    
    func bindViewModel(_ viewModel: SuggestionsViewModel) {
        self.viewModel = viewModel
        
        viewModel.tagSuggestions
            .bind(to: tagCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        bindAction()
        
        viewModel.tagSuggestions
            .asObservable()
            .subscribe(onNext: {[weak self] (tagSuggestions) in
                guard let strongSelf = self else { return }
                strongSelf.tagCollectionView.reloadData()
                strongSelf.layoutIfNeeded()
                strongSelf.tagCollectionViewHeight.constant = strongSelf.viewModel.tagSuggestions.value.isEmpty ? 0 : strongSelf.tagCollectionView.contentSize.height
                strongSelf.contentSizeDidChangeBlock?()
            })
            .disposed(by: disposeBag)

    }
    
    func bindAction() {
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.seeAllDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
                        
        tagCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
               strongSelf.tagDidClickBlock?(strongSelf.viewModel.tagSuggestions.value[indexPath.row].tag.name)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension RecommendedTagTableViewCell {
    private func configureTagCollectionView() {
        tagCollectionViewHeight.constant = 0
        tagCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension RecommendedTagTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(viewModel.tagSuggestions.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 30)
    }
}
