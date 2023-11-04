//
//  ItineraryDetailActivityFooterTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 29/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import SwiftRichString

class ItineraryDetailActivityFooterTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var firstCommentLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var bookmarkLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var viewAllCommentButton: UIButton!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var descriptionLabelTop: NSLayoutConstraint!
    @IBOutlet weak var moreButtonTop: NSLayoutConstraint!
        
    typealias CommentDidClickBlock = (ItineraryDetailViewModel) -> Void
    var commentDidClickBlock: CommentDidClickBlock?
    
    typealias ItineraryDidSaveBlock = (ItineraryDetailViewModel) -> Void
    var itineraryDidSaveBlock: ItineraryDidSaveBlock?
    
    typealias ViewCommentDidSaveBlock = () -> Void
    var viewCommentDidSaveBlock: ViewCommentDidSaveBlock?
    
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    
    var viewModel: ItineraryDetailViewModel!
    private var disposeBag = DisposeBag()
    var moreAttributeString: [NSAttributedString.Key : Any] {
        return [.underlineStyle: NSUnderlineStyle.single.rawValue,
        NSAttributedString.Key.foregroundColor: Styles.g888888,
        NSAttributedString.Key.font: Styles.customFontLight(15)]
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributedString = NSAttributedString(string: "More", attributes: moreAttributeString)
        moreButton.setAttributedTitle(attributedString, for: .normal)
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
extension ItineraryDetailActivityFooterTableViewCell {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        self.viewModel = viewModel
        
        viewModel.comment
            .asObservable()
            .filterNil()
            .bind {[weak self] (comment) in
                let normal = Style {
                    $0.color = Styles.g504F4F
                    $0.font = Styles.customFontLight(15)
                    $0.lineSpacing = 7
                }
                
                let tag = Style {
                    $0.color = Styles.g504F4F
                    $0.font = Styles.customFontMedium(15)
                }
                let myGroup = StyleGroup(base: normal, ["TagUser": tag])
                let str = "<TagUser>@" + comment.user.displayName + "</TagUser> " + comment.message
                self?.firstCommentLabel.attributedText = str.set(style: myGroup)
                self?.updateLayout()
        }
        .disposed(by: disposeBag)
        
        viewModel.model.isComment
            .asDriver()
            .drive(commentButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        viewModel.model.isLike
            .asDriver()
            .drive(likeButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        viewModel.model.isSave
            .asDriver()
            .drive(bookmarkButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        viewModel.model.likeCount
            .asDriver()
            .map {Styles.numberFormatter.string(from: NSNumber(value:$0))}
            .drive(likeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.commentCount
            .asDriver()
            .map {Styles.numberFormatter.string(from: NSNumber(value:$0))}
            .drive(commentLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.isComment
        .asDriver()
        .drive(commentButton.rx.isSelected)
        .disposed(by: disposeBag)
        
        viewModel.model.savedCount
            .asDriver()
            .map {Styles.numberFormatter.string(from: NSNumber(value:$0))}
            .drive(bookmarkLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.commentCount
            .asDriver()
            .map {"View all \(Styles.numberFormatter.string(from: NSNumber(value:$0))!) \($0 <= 1 ? "comment" : "comments")"}
            .drive(viewAllCommentButton.rx.title())
            .disposed(by: disposeBag)
        
        
        updateLayout()
        
        bindAction()
    }
    
    func bindAction() {
        likeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.likeButton.playBounceAnimation()
                strongSelf.viewModel.like()
            }.disposed(by: disposeBag)
        
        bookmarkButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.bookmarkButton.playBounceAnimation()
                strongSelf.itineraryDidSaveBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        commentButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.commentDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        viewAllCommentButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewCommentDidSaveBlock?()
        }.disposed(by: disposeBag)
        
        addCommentButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewCommentDidSaveBlock?()
        }.disposed(by: disposeBag)
        
        moreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                let isExpanded = strongSelf.firstCommentLabel.numberOfLines == 0
                strongSelf.firstCommentLabel.numberOfLines = !isExpanded ? 0 : 2
                let attributedString = NSAttributedString(string: !isExpanded ? "Less" : "More", attributes: strongSelf.moreAttributeString)
                strongSelf.moreButton.setAttributedTitle(attributedString, for: .normal)                                
                strongSelf.firstCommentLabel.sizeToFit()
                strongSelf.contentSizeDidChangeBlock?()
        }.disposed(by: disposeBag)
        
    }
}

// MARK: - Private
extension ItineraryDetailActivityFooterTableViewCell {
    private func updateLayout() {
        // update Layout
        let comment = viewModel.comment.value
        var description = ""
        if comment != nil {
            description = comment!.user.displayName + " " + comment!.message
        }
        
        let isEmptyDescription = description.isEmpty
        
        let showMoreButton = !isEmptyDescription &&  description.heightWithConstrainedWidth(width: firstCommentLabel.frame.width, font: firstCommentLabel.font) > 38
        descriptionLabelTop.constant = isEmptyDescription ? 0 : 16
        moreButton.isHidden = !showMoreButton
        moreButtonTop.constant = moreButton.isHidden ? moreButton.frame.height * -1 : 4
        contentSizeDidChangeBlock?()
    }
}

