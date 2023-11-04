//
//  SearchUserTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchUserTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var followedView: UIView!
    var viewModel: UserCellViewModel!
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
extension SearchUserTableViewCell {
    
    func bindViewModel(_ viewModel: UserCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.name.asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.location.asDriver()
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.hideFollowView.asDriver()            
            .drive(followedView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.itineraryCount.asDriver()            
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.profileImage
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (reference) in
                guard let strongSelf = self else { return }
                strongSelf.profileImageView.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                    if image != nil {
                        strongSelf.profileImageView.image = image
                    }
                })
            })
            .disposed(by: disposeBag)
    }
    
}
