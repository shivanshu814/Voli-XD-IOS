//
//  TableFooterView.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TableFooterView: UIView {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreButton: UIButton!
    @IBOutlet weak var noMoreResultLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var seperateView: UIView!
    
    @IBOutlet weak var loadMoreButtonTop: NSLayoutConstraint!
    var sizingCell: TagCollectionViewCell!
    var tagCellViewModels = [TagCellViewModel]()
    weak var superViewController: UIViewController!
    weak var disposeBag: DisposeBag!
    var showLoadMore = true
    
    static var instance: TableFooterView {
        let nib = UINib(nibName: "TableFooterView", bundle: nil)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! TableFooterView
        return view
    }
        
    
    func setup(_ superViewController: UIViewController, disposeBag: DisposeBag, showRelatedTag: Bool = true) {
        self.superViewController = superViewController
        self.disposeBag = disposeBag
        
        loadMoreButtonTop.constant = showLoadMore ? 24 : -73
        loadMoreButton.isHidden = !showLoadMore
        noMoreResultLabel.isHidden = !showLoadMore
        seperateView.isHidden = true
        
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.superViewController.showSeeAllPage(SuggestionsViewModel(itineraryViewModel: nil, type: .tag, isAll: true))
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let viewModel = SuggestionsViewModel(tagViewModel: TagViewModel(tag: (strongSelf.tagCellViewModels[indexPath.row]).tag.name))
                strongSelf.superViewController.showSeeAllPage(viewModel)
        }.disposed(by: disposeBag)
        
        self.configureTagCollectionView()
        
        if !showRelatedTag {
            titleLabel.isHidden = true
            seeAllButton.isHidden = true
            collectionViewHeight.constant = 0
            var rect = frame
            rect.size.height = 80
            frame = rect
        }
        
    }
    
    func bindTags(_ tags: BehaviorRelay<[TagCellViewModel]>) {
            
        
        seperateView.isHidden = !showLoadMore
        
        tags.bind(to: collectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                cell.backgroundColor = Styles.pF6F2FE
                cell.tagLabel.textColor = Styles.g504F4F
            }.disposed(by: disposeBag)
        
        tags.asObservable()
            .subscribe(onNext: {[weak self] (tagSuggestions) in
                guard let strongSelf = self else { return }
                strongSelf.tagCellViewModels = tagSuggestions
                strongSelf.collectionView.reloadData()
                strongSelf.superview?.layoutIfNeeded()
                strongSelf.collectionViewHeight.constant = tagSuggestions.isEmpty ? 0 : strongSelf.collectionView.contentSize.height
                var rect = strongSelf.frame
                rect.size.height = strongSelf.collectionView.frame.origin.y + strongSelf.collectionViewHeight.constant + 40
                strongSelf.frame = rect
                strongSelf.superview?.layoutIfNeeded()
                (strongSelf.superview as? UITableView)?.beginUpdates()
                (strongSelf.superview as? UITableView)?.endUpdates()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func configureTagCollectionView() {
        collectionViewHeight.constant = 0
        collectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        collectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 8
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 8
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension TableFooterView : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(tagCellViewModels[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width), height: 30)
    }
}
