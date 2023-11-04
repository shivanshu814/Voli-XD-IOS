//
//  ChannelTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 21/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ChannelTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var isFollowingView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var countLabelView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    var viewModel: ChannelCellViewModel!
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

// MARK: - RX
extension ChannelTableViewCell {
    
    func bindViewModel(_ viewModel: ChannelCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.date
            .asDriver()
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.name
            .asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.message
            .asDriver()
            .drive(messageLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.unreadCount
            .asObservable()
            .bind {[weak self] (count) in
                self?.countLabel.text = String(count)
                self?.countLabelView.isHidden = count == 0
        }
        .disposed(by: disposeBag)
        
        viewModel.isFollowing
            .asDriver()
            .map {!$0}
            .drive(isFollowingView.rx.isHidden)
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
