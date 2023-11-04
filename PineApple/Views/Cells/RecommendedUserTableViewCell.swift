//
//  RecommendedUserTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class RecommendedUserTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    typealias SeeAllDidClickBlock = (SuggestionsViewModel) -> Void
    var seeAllDidClickBlock: SeeAllDidClickBlock?
    typealias UserDidClickBlock = (ProfileDetailViewModel) -> Void
    var userDidClickBlock: UserDidClickBlock?
    
    var viewModel: SuggestionsViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableView()
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
extension RecommendedUserTableViewCell {
    
    func bindViewModel(_ viewModel: SuggestionsViewModel) {
        self.viewModel = viewModel
        
        viewModel.userSuggestions
            .bind(to: tableView.rx.items(cellIdentifier: "UserTableViewCell", cellType: UserTableViewCell.self)) { (row, element, cell) in                
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        bindAction()
        
    }
    
    func bindAction() {
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.seeAllDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                
                let user = strongSelf.viewModel.userSuggestions.value[indexPath.row].user
                let vm = ProfileDetailViewModel(user: user)
                strongSelf.userDidClickBlock?(vm)
                
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension RecommendedUserTableViewCell {
    private func configureTableView() {
        tableView.register(nibWithCellClass: UserTableViewCell.self)
    }
}

