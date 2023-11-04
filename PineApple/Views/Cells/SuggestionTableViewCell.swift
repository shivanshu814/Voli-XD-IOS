//
//  SuggestionTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 30/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SuggestionTableViewCell: UITableViewCell, ViewModelBased{

    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var titleLabelHeight: NSLayoutConstraint!
    typealias SuggestionDidClickBlock = (ItineraryDetailViewModel, IndexPath) -> Void
    var suggestionDidClickBlock: SuggestionDidClickBlock?
    typealias SeeAllDidClickBlock = (SuggestionsViewModel) -> Void
    var seeAllDidClickBlock: SeeAllDidClickBlock?
    
    
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
        titleLabelHeight.constant = 32
    }

}

// MARK: - RX
extension SuggestionTableViewCell {
    
    func bindViewModel(_ viewModel: SuggestionsViewModel) {
        self.viewModel = viewModel
          
        let displayName = viewModel.itineraryViewModel?.user.value?.displayName ?? ""
        titleLabel.text = viewModel.type == .collection ? viewModel.savedCollection?.name : viewModel.type.title.replacingOccurrences(of: "XXX", with: displayName)
        
        viewModel.similarSubType
            .asObservable()
            .bind {[weak self] (type) in
                if type != nil {
                    self?.titleLabel.text = type!.title
                }
        }
        .disposed(by: disposeBag)
        
        viewModel.suggestions
            .bind(to: collectionView.rx.items(cellIdentifier: "ItineraryCollectionViewCell", cellType: ItineraryCollectionViewCell.self)) { (row, element, cell) in
                element.indexPath = IndexPath(row: row, section: 0)
                cell.bindViewModel(element)
                cell.itemDidClickBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    if let indexPath = vm.indexPath {
                        strongSelf.suggestionDidClickBlock?(strongSelf.viewModel.suggestions.value[indexPath.row], indexPath)
                    }
                }
                
            }.disposed(by: disposeBag)
        
        bindAction()
        
    }
    
    func bindAction() {
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.seeAllDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.suggestionDidClickBlock?(strongSelf.viewModel.suggestions.value[indexPath.row], indexPath)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension SuggestionTableViewCell {
    
    private func configureTagCollectionView() {
        collectionView.register(nibWithCellClass: ItineraryCollectionViewCell.self)
    }
}


