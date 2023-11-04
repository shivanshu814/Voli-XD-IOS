//
//  FollowedUserTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import FirebaseUI

class FollowedUserTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seeAllButton: UIButton!
    var viewModel: ProfileDetailViewModel!
    private var disposeBag = DisposeBag()
    typealias SeeAllDidClickBlock = () -> Void
    var seeAllDidClickBlock: SeeAllDidClickBlock?
    typealias ItemDidClickBlock = (ProfileDetailViewModel) -> Void
    var itemDidClickBlock: ItemDidClickBlock?
    
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
extension FollowedUserTableViewCell {
    
    func bindViewModel(_ viewModel: ProfileDetailViewModel) {
        self.viewModel = viewModel
        
        viewModel.followingUsers
            .bind(to: collectionView.rx.items(cellIdentifier: "FollowingUserCell", cellType: CollectionViewCell.self)) {(row, element, cell) in
                
                let storageRef = viewModel.storage.reference()
                let reference = storageRef.child(element.thumbnail)
                cell.imagesViews?.first?.backgroundColor = UIColor.lightGray
                cell.imagesViews?.first?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                    if image != nil {
                        cell.imagesViews?.first?.image = image
                    } else {
                        print(error?.localizedDescription ?? "")
                    }
                })
                
            }.disposed(by: disposeBag)
        
        bindAction()
    }
    
    func bindAction() {
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let user = strongSelf.viewModel.followingUsers.value[indexPath.row]                
                strongSelf.itemDidClickBlock?(ProfileDetailViewModel(user: user))                
            }.disposed(by: disposeBag)
        
        seeAllButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.seeAllDidClickBlock?()
            }.disposed(by: disposeBag)
    }
    
}
