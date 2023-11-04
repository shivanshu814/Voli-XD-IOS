//
//  TagFooterCollectionReusableView.swift
//  PineApple
//
//  Created by Tao Man Kit on 10/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TagFooterCollectionReusableView: UICollectionReusableView, ViewModelBased {
    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreButton: UIButton!
    @IBOutlet weak var noMoreResultLabel: UILabel!
    var viewModel: TagViewModel!
    private var disposeBag = DisposeBag()
    var sizingCell: TagCollectionViewCell!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    typealias ContentSizeDidChangeBlock = (CGFloat) -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    
    typealias RelatedTagDidChangeBlock = (TagCellViewModel) -> Void
    var relatedTagDidChangeBlock: RelatedTagDidChangeBlock?
    
    typealias SeeAllDidChangeBlock = () -> Void
    var seeAllDidChangeBlock: SeeAllDidChangeBlock?
    
    override func awakeFromNib() {
        configureTagCollectionView()
        
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

// MARK: - RX
extension TagFooterCollectionReusableView {
    
    func bindViewModel(_ viewModel: TagViewModel) {
        self.viewModel = viewModel
        
        viewModel.paging.isMore
            .asObservable()
            .bind {[weak self] (isMore) in
                self?.loadMoreButton.isHidden = !isMore
                self?.noMoreResultLabel.isHidden = isMore
        }
        .disposed(by: disposeBag)
        
        viewModel.relatedTagViewModel.relatedTags
            .bind(to: collectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
//                cell.backgroundColor = Styles.pCFC2FF
//                cell.tagLabel.textColor = Styles.black
            }.disposed(by: disposeBag)
        
        viewModel.relatedTagViewModel.relatedTags
            .asObservable()
            .bind {[weak self] (tagSuggestions) in
                guard let strongSelf = self else { return }
                strongSelf.collectionView.reloadData()
                strongSelf.layoutIfNeeded()
                
                strongSelf.collectionViewHeight.constant = strongSelf.viewModel.relatedTagViewModel.relatedTags.value.isEmpty ? 0 : strongSelf.collectionView.contentSize.height
                
                var rect = strongSelf.frame
                rect.size.height = strongSelf.collectionView.frame.origin.y + strongSelf.collectionViewHeight.constant + 20
                strongSelf.frame = rect
                
                strongSelf.contentSizeDidChangeBlock?(rect.height)
                
            }
            .disposed(by: disposeBag)
        
        bindAction()
                
    }
    
    func bindAction() {
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.seeAllDidChangeBlock?()
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.relatedTagDidChangeBlock?(strongSelf.viewModel.relatedTagViewModel.relatedTags.value[indexPath.row])
            }.disposed(by: disposeBag)
        
        loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.loadMoreButton.isHidden = true
                strongSelf.activityIndicatorView.startAnimating()
                strongSelf.viewModel.fetchTagActivities { (result, error) in
                    self?.activityIndicatorView.stopAnimating()
                    if let error = error {
                        Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
        }.disposed(by: disposeBag)
    }
    
}

// MARK - Private
extension TagFooterCollectionReusableView {
    private func configureTagCollectionView() {
//        collectionViewHeight.constant = 0
        collectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        collectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
    }
}

extension TagFooterCollectionReusableView : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(viewModel.relatedTagViewModel.relatedTags.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 30)
    }
}

