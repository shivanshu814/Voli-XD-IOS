//
//  ItineraryHeaderTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ItineraryHeaderTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    var isReloading = false
    var sizingCell: TagCollectionViewCell!
    typealias ItemDidClickBlock = () -> Void
    var itemDidClickBlock: ItemDidClickBlock?
    
    typealias LocationDidClickBlock = () -> Void
    var locationDidClickBlock: LocationDidClickBlock?
    
    typealias SortDidClickBlock = () -> Void
    var sortDidClickBlock: SortDidClickBlock?
    
    var viewModel: ItinerariesFilterViewModel!
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
extension ItineraryHeaderTableViewCell {
    
    func bindViewModel(_ viewModel: ItinerariesFilterViewModel) {
        self.viewModel = viewModel
        
        viewModel.location
            .asDriver()
            .map{$0.longName}
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.tags
            .bind(to: tagsCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        viewModel.tags
            .asObservable()
            .bind {[weak self] (tags) in
                self?.isReloading = true
        }
        .disposed(by: disposeBag)
        
        tagsCollectionView.contentOffset.x = viewModel.contentOffsetX
        isReloading = false
        
        bindAction()
    }
    
    func bindAction() {
        tagsCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let isSelected = strongSelf.viewModel!.tags.value[indexPath.row].isSelected.value
                strongSelf.viewModel!.tags.value[indexPath.row].isSelected.accept(!isSelected)
                strongSelf.viewModel.updateModel()
                strongSelf.viewModel.contentOffsetX = strongSelf.tagsCollectionView.contentOffset.x
                strongSelf.itemDidClickBlock?()
            }.disposed(by: disposeBag)
        
        locationButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.locationDidClickBlock?()
            }.disposed(by: disposeBag)
        
        sortButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.sortDidClickBlock?()
            }.disposed(by: disposeBag)
        
    }
    
}

// MARK: - Private
extension ItineraryHeaderTableViewCell {
    
    private func configureTagCollectionView() {
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 8
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 8
    }
}

// MARK: - UIScrollViewDelegate
extension ItineraryHeaderTableViewCell: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && !isReloading {
            viewModel.contentOffsetX = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isReloading {
            viewModel.contentOffsetX = scrollView.contentOffset.x
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension ItineraryHeaderTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let vm = viewModel.tags.value[indexPath.row]
        sizingCell.bindViewModel(vm)
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 30)
    }
}
