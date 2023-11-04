//
//  CommentTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 8/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftRichString

class CommentTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var comment: UIButton!
    typealias ItemDidReportBlock = (CommentCellViewModel) -> Void
    var itemDidReportBlock: ItemDidReportBlock?
    var viewModel: CommentCellViewModel!
    private var disposeBag = DisposeBag()
    
    typealias CommentButtonDidClickBlock = (CommentCellViewModel) -> Void
    var commentButtonDidClickBlock: CommentButtonDidClickBlock?

    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        configureLongPressGesture()
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
extension CommentTableViewCell {
    
    func bindViewModel(_ viewModel: CommentCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.name
            .asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.message
            .asObservable()
            .bind {[weak self] (message) in
                guard let strongSelf = self else { return }
                let normal = Style {
                    $0.color = Styles.g504F4F
                    $0.font = Styles.customFontLight(15)
                    $0.lineSpacing = 4
                }
                
                let tag = Style {
                    $0.color = Styles.p8437FF
                    $0.font = Styles.customFontLight(15)
                    $0.lineSpacing = 4
                }
                let myGroup = StyleGroup(base: normal, ["TagUser": tag])
                var str = message
                strongSelf.viewModel.model.tags.forEach {
                    str = str.replacingOccurrences(of: "@\($0)", with: "<TagUser>@\($0)</TagUser>")
                }
                
                self?.messageLabel.attributedText = str.set(style: myGroup)
        }
        .disposed(by: disposeBag)
        
        viewModel.profileImage
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (reference) in
                guard let strongSelf = self else { return }
                strongSelf.profileButton.contentMode = .scaleAspectFill
                strongSelf.profileButton.imageView?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                    if image != nil {
                        strongSelf.profileButton.setImage(image, for: .normal)                        
                    }
                })
            })
            .disposed(by: disposeBag)
        
        viewModel.createDate
            .asDriver()
            .map{Styles.dateFormatter_HHmmaddMMYYYY.string(from: $0)}
            .map{ $0.ends(with: String(Date().year)) ? $0.replacingOccurrences(of: "/\(String(Date().year))", with: "") : $0}
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.likeCount
            .asDriver()
            .map{$0.shorted()}
            .drive(likeCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isLike
            .asDriver()
            .drive(likeButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        bindAction()
    }
    
    func bindAction() {
        likeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.like()
            }.disposed(by: disposeBag)
        
        comment.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.commentButtonDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension CommentTableViewCell {
    private func configureLongPressGesture() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressGesture))
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPressGesture() {
        itemDidReportBlock?(viewModel)
    }
}
