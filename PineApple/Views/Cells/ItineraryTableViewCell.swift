//
//  ItineraryTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseUI
import SDWebImage

class ItineraryTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateLocationLabel: UILabel!
    @IBOutlet weak var attachmentCollectionView: UICollectionView!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var bookmarkLabel: UILabel!
    var sizingCell: TagCollectionViewCell!
    typealias ItemDidClickBlock = (ItineraryDetailViewModel) -> Void
    var itemDidClickBlock: ItemDidClickBlock?
    
    typealias CommentDidClickBlock = (ItineraryDetailViewModel) -> Void
    var commentDidClickBlock: CommentDidClickBlock?
    
    typealias SaveDidClickBlock = (ItineraryDetailViewModel) -> Void
    var saveDidClickBlock: SaveDidClickBlock?
    
    var viewModel: ItineraryDetailViewModel!
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
extension ItineraryTableViewCell {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        self.viewModel = viewModel
        
        if viewModel.model.isPrivate.value {
            profileImage.image = #imageLiteral(resourceName: "UserIcon-invisible")
            profileImage.contentMode = .center
        } else {
            profileImage.contentMode = .scaleAspectFill
        }
        
        viewModel.model.profileImage
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (reference) in
                guard let strongSelf = self else { return }
                if !strongSelf.viewModel.model.isPrivate.value {
                    strongSelf.profileImage.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                        if image != nil {
                            strongSelf.profileImage.image = image
                        }
                    })
                }
                
            })
            .disposed(by: disposeBag)
        
        viewModel.model.createDate
            .asDriver()
            .map { $0.toDateString}
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        (viewModel.model.rows.value[0] as! RequiredFieldViewModel).value
            .asDriver()
            .map { NSAttributedString(string: $0, attributes: self.titleLabel.attributedText?.attributes)}
            .drive(titleLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.timeSpend, viewModel.model.activityViewModels.first!.subLocalityString) { (x, y) -> String in
            return x + " • " + y
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (timeLocation) in
                guard let strongSelf = self else { return }
                strongSelf.dateLocationLabel.attributedText = NSAttributedString(string: timeLocation, attributes: strongSelf.dateLocationLabel.attributedText?.attributes)
            })
            .disposed(by: disposeBag)
       
        viewModel.tags
            .bind(to: tagsCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                element.showPrefix()
                cell.bindViewModel(element)
                cell.enableNoBoarderStyle()
            }.disposed(by: disposeBag)
        
        viewModel.attachments
            .bind(to: attachmentCollectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        viewModel.model.isLike
            .asObservable()
            .bind {[weak self] (isLike) in
                self?.likeButton.isSelected = isLike
        }
        .disposed(by: disposeBag)
        
        viewModel.model.isSave
            .asObservable()
            .bind {[weak self] (isLike) in
                self?.bookmarkButton.isSelected = isLike
        }
        .disposed(by: disposeBag)
        
        viewModel.model.isComment
            .asObservable()
            .bind {[weak self] (isComment) in
                self?.commentButton.isSelected = isComment
        }
        .disposed(by: disposeBag)
        
        viewModel.model.likeCount
            .asDriver()
            .map {$0.shorted()}
            .drive(likeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.commentCount
            .asDriver()
            .map {$0.shorted()}
            .drive(commentLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.savedCount
            .asDriver()
            .map {$0.shorted()}
            .drive(bookmarkLabel.rx.text)
            .disposed(by: disposeBag)
        
        bindAction()
    }
    
    func bindAction() {
        
        likeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if !Globals.rootViewController.showNoPermissionViewIfNeeded() {
                    strongSelf.viewModel.like()
                }
        }.disposed(by: disposeBag)
        
        bookmarkButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if !Globals.rootViewController.showNoPermissionViewIfNeeded() {
                    strongSelf.saveDidClickBlock?(strongSelf.viewModel)
                }
        }.disposed(by: disposeBag)
        
        commentButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if !Globals.rootViewController.showNoPermissionViewIfNeeded() {
                    strongSelf.commentDidClickBlock?(strongSelf.viewModel)
                }
        }.disposed(by: disposeBag)
        
        tagsCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.itemDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        attachmentCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.itemDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
    }
    
}

// MARK: - Private
extension ItineraryTableViewCell {
    
    private func configureTagCollectionView() {
        attachmentCollectionView.register(nibWithCellClass: AttachmentCollectionViewCell.self)
        
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        sizingCell.tagLabel.font = Styles.customFontLight(13)
        sizingCell.enableNoBoarderStyle()
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 8
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 8
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension ItineraryTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellViewModel = viewModel.tags.value[indexPath.row]
        cellViewModel.showPrefix()
        sizingCell.bindViewModel(cellViewModel)
        
        let size = sizingCell.cellSize
        return CGSize(width: size.width , height: collectionView.height)
    }
}
