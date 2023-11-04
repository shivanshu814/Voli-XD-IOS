//
//  SearchTagTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchTagTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    var viewModel: TagCellViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
extension SearchTagTableViewCell {
    
    func bindViewModel(_ viewModel: TagCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.name.asDriver()
            .drive(tagLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.count.asDriver()
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)
        
    }
    
}
