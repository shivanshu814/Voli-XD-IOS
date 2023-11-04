//
//  SortPopupView.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SortPopupView: UIView, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var sortPopupView: UIView!
    @IBOutlet weak var sortTableView: UITableView!    
    @IBOutlet weak var sortPopupDismissButton: UIButton!

    var superViewController: UIViewController?
    var viewModel: ItinerariesViewModel! {
        didSet {
            bindViewModel(viewModel)
            bindAction()
        }
    }
    
    var suggestionsViewModel: SuggestionsViewModel! {
        didSet {
            bindViewModel(suggestionsViewModel)
            bindAction()
        }
    }
    
    private let disposeBag = DisposeBag()
    typealias CompletionBlock = () -> Void
    var completionBlock: CompletionBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableView()
    }
}

// MARK: - RX
extension SortPopupView {
    
    func bindViewModel(_ viewModel: ItinerariesViewModel) {
        viewModel.sortOptions
        .bind(to: sortTableView.rx.items(cellIdentifier: "OptionTableViewCell", cellType: OptionTableViewCell.self)) {[weak self] (row, element, cell) in
            guard let strongSelf = self else { return }
            cell.titleLabel.text = element.displayName
            let isSelected = strongSelf.viewModel.filterViewModel.sortBy.value.displayName == element.displayName
            cell.backgroundColor = isSelected ? Styles.pCFC2FF : UIColor.white            
        }.disposed(by: disposeBag)
    }
    
    func bindViewModel(_ viewModel: SuggestionsViewModel) {
        viewModel.tagViewModel.sortOptions
        .bind(to: sortTableView.rx.items(cellIdentifier: "OptionTableViewCell", cellType: OptionTableViewCell.self)) {[weak self] (row, element, cell) in
            cell.titleLabel.text = element.displayName
            let isSelected = viewModel.tagViewModel.sortBy.value.displayName == element.displayName
            cell.backgroundColor = isSelected ? Styles.pCFC2FF : UIColor.white
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        sortTableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                if strongSelf.suggestionsViewModel == nil {
                    strongSelf.viewModel.filterViewModel.sortBy.accept(sortByOption[indexPath.row])
                } else {
                    strongSelf.suggestionsViewModel.tagViewModel.sortBy.accept(sortByOption[indexPath.row])
                }
                strongSelf.sortTableView.reloadData()
                strongSelf.completionBlock?()
                strongSelf.sortPopupDismissButton.sendActions(for: .touchUpInside)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension SortPopupView {
    
    private func configureTableView() {
        sortTableView.register(UINib(nibName: "OptionTableViewCell", bundle: nil), forCellReuseIdentifier: "OptionTableViewCell")
    }
}

