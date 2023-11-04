//
//  UserTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import FirebaseUI
import MessageUI

class UserTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    enum Mode {
        case recommend
        case share
        case message
        case following
        
        var title: String {
            switch self {
            case .recommend, .message: return "Message"
            case .following: return "Following"
            default: return "Share"
            }
        }
        
        var placeholder: String {
            switch self {
            case .recommend, .message: return "Following user"
            case .following: return "Following user"
            default: return "Following user"
            }
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var itineraryCountLabel: UILabel!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    @IBOutlet weak var contentTop: NSLayoutConstraint!
    @IBOutlet weak var contentBottom: NSLayoutConstraint!
    typealias ShareDidClickBlock = (User) -> Void
    var shareDidClickBlock: ShareDidClickBlock?
    
    var sizingCell: TagCollectionViewCell!
    var viewModel: UserCellViewModel!
    var isShareMode: Mode = .recommend
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
        isShareMode = .recommend
    }
    
}

// MARK: - RX
extension UserTableViewCell {
    
    func bindViewModel(_ viewModel: UserCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.setup()
        configureLayout()
        
        if isShareMode == .recommend {
            viewModel.isFollowing
                .asDriver()
                .map{$0 ? "Unfollow" : "Follow"}
                .drive(shareButton.rx.title())
                .disposed(by: disposeBag)
        }
        
        viewModel.name
            .asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
                
        viewModel.location
            .asDriver()
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.itineraryCount
            .asDriver()
            .drive(itineraryCountLabel.rx.text)
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
        
        bindAction()
    }
    
    func bindAction() {
        shareButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.isShareMode == .recommend {
                    if !Globals.rootViewController.showNoPermissionViewIfNeeded() {
                        strongSelf.viewModel.follow()
                        
                    }
                } else {
                    strongSelf.shareDidClickBlock?(strongSelf.viewModel.user)
                }
                
                
        }.disposed(by: disposeBag)
                
    }
    
}

// MARK: - Private
extension UserTableViewCell {
    
    private func configureLayout() {        
        let isShare = isShareMode == .share
        shareButton.isHidden = isShareMode == .following
        shareButton.setTitle(isShareMode == .recommend ? "Follow" : isShare ? "Share" : "Message" , for: .normal)
        
        itineraryCountLabel.isHidden = isShareMode != .recommend
    }
    
    private func configureTagCollectionView() {
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension UserTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(viewModel.tags.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 29)
    }
}

