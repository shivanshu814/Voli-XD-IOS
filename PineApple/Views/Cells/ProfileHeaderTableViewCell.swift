//
//  ProfileHeaderTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MaterialComponents.MaterialTextFields
import FirebaseUI
import MessageUI

class ProfileHeaderTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var numberOfItineraryLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followerLabel: UILabel!
    @IBOutlet weak var myInterestsLabel: UILabel!
    @IBOutlet weak var tagsEditButton: UIButton!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var tagErrorLabel: UILabel!
    @IBOutlet weak var dummyTextField: MDCTextField!
    @IBOutlet weak var tagTextField: MDCTextField!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var aboutEditButton: UIButton!
    @IBOutlet weak var aboutValueLabel: UILabel!
    @IBOutlet weak var aboutTextViewBaseView: UIView!
    @IBOutlet weak var aboutTextView: UITextView!
    @IBOutlet weak var aboutTextViewPlaceHolder: UILabel!
    @IBOutlet weak var aboutErrorLabel: UILabel!
    @IBOutlet weak var aboutPlaceHolderLabel: UILabel!
    @IBOutlet weak var followingStackView: UIStackView!
    @IBOutlet weak var tagCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsCollectionViewTop: NSLayoutConstraint!
    @IBOutlet weak var tagsStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myInterestHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewBaseViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    var viewModel: ProfileDetailViewModel!
    private var disposeBag = DisposeBag()
    var sizingCell: TagCollectionViewCell!
    var tagsTextFieldControllerUnderline: MDCTextInputControllerUnderline!
    var aboutTextFieldControllerUnderline: MDCTextInputControllerUnderline!
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    typealias TagContentSizeDidChangeBlock = () -> Void
    var tagContentSizeDidChangeBlock: TagContentSizeDidChangeBlock?
    typealias EditProfileDidClickBlock = () -> Void
    var editProfileDidClickBlock: EditProfileDidClickBlock?
    typealias SettingDidClickBlock = () -> Void
    var settingDidClickBlock: SettingDidClickBlock?
    typealias TagDoneDidClickBlock = () -> Void
    var tagDoneDidClickBlock: TagDoneDidClickBlock?
    typealias MessageDidClickBlock = (User) -> Void
    var messageDidClickBlock: MessageDidClickBlock?
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTextField()        
        configureTagCollectionView()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configureButtons()
    }
    
    deinit {
        aboutTextView.removeObserver(self, forKeyPath: "contentSize")
    }

}

// MARK: - RX
extension ProfileHeaderTableViewCell {
    
    func bindViewModel(_ viewModel: ProfileDetailViewModel) {
        self.viewModel = viewModel
        
        if !viewModel.isOwner.value {
            rightButton.isEnabled = !viewModel.user!.isPrivate
            rightButton.alpha = rightButton.isEnabled ? 1 : 0.5
        }
        
        viewModel.isFollowing
            .asObservable()
            .filterNil()
            .bind {[weak self] (isFollowing) in
                guard let strongSelf = self else { return }
                if !strongSelf.viewModel.isOwner.value {
                    strongSelf.leftButton.setTitle(isFollowing ? "Unfollow" : "Follow", for: .normal)
                    
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.isOwner
            .asObservable()
            .bind {[weak self] (isOwner) in
                guard let strongSelf = self else { return }
                if isOwner {
                    strongSelf.leftButton.isHidden = false
                    strongSelf.rightButton.isHidden = false
                }
                strongSelf.myInterestsLabel.isHidden = !isOwner
                strongSelf.followingStackView.isHidden = !isOwner
                strongSelf.tagsCollectionViewTop.constant = isOwner ? 21 : 0
                strongSelf.myInterestHeight.constant = isOwner ? 29 : 0
                if isOwner {
                    strongSelf.leftButton.setTitle("Edit profile", for: .normal)
                }                
                strongSelf.rightButton.setTitle(isOwner ? "Setting" : "Message", for: .normal)
            }
            .disposed(by: disposeBag)
        
        viewModel.isEditing
            .asObservable()
            .bind {[weak self] (isEditing) in
                guard let strongSelf = self else { return }
                strongSelf.tagsEditButton.isHidden = !strongSelf.viewModel.isOwner.value || !isEditing
                strongSelf.aboutEditButton.isHidden = !strongSelf.viewModel.isOwner.value || !isEditing
            }
            .disposed(by: disposeBag)
        
        viewModel.isInterestsEditing
            .asObservable()
            .bind {[weak self] (isEditing) in
                guard let strongSelf = self else { return }
                strongSelf.tagTextField.isHidden = !isEditing
            }
            .disposed(by: disposeBag)
        
        viewModel.isAboutEditing
            .asObservable()
            .bind {[weak self] (isEditing) in
                guard let strongSelf = self else { return }
                strongSelf.aboutTextViewBaseView.isHidden = !isEditing
                strongSelf.aboutValueLabel.isHidden = isEditing || strongSelf.viewModel.about.value.isEmpty
                
                
            }
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
        
        viewModel.name.asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.location.asDriver()
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.numberOfItinerary.asDriver()
            .map {Int($0)! > 1 ? "\($0) itineraries" : "\($0) itinerary"}
            .drive(numberOfItineraryLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.follower.asDriver()
            .drive(followerLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.following.asDriver()
            .drive(followingLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.tags
            .bind(to: tagsCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        viewModel.location.asDriver()
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.about
            .asObservable()
            .bind {[weak self] (about) in
                guard let strongSelf = self else { return }
                let name = strongSelf.viewModel.name.value
                strongSelf.aboutPlaceHolderLabel.text = "\(strongSelf.viewModel.isOwner.value ? "You" : name) hasn’t written the About yet."
                strongSelf.aboutPlaceHolderLabel.isHidden = !about.isEmpty
                strongSelf.aboutValueLabel.isHidden = about.isEmpty
                strongSelf.aboutTextViewPlaceHolder.isHidden = !about.isEmpty
                strongSelf.aboutValueLabel.attributedText = NSAttributedString(string: about, attributes: strongSelf.aboutValueLabel.attributedText?.attributes)
                
                strongSelf.aboutTextView.text = about
            }
            .disposed(by: disposeBag)
        
        viewModel.tags
            .asObservable()
            .bind {[weak self] (tags) in
                guard let strongSelf = self else { return }
                strongSelf.layoutIfNeeded()
                strongSelf.tagCollectionViewHeight.constant = tags.isEmpty ? 0 : strongSelf.tagsCollectionView.contentSize.height
                strongSelf.tagsStackViewHeight.constant = strongSelf.tagCollectionViewHeight.constant
        }
        .disposed(by: disposeBag)
        
        bindAction()
        
        DispatchQueue.main.async {
            self.aboutTextView.isScrollEnabled = false
        }
    }
    
    func bindAction() {
        
        leftButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.viewModel!.isOwner.value || Globals.currentUser == nil {
                    strongSelf.editProfileDidClickBlock?()
                } else {
                    strongSelf.viewModel.follow()
                }
            }.disposed(by: disposeBag)
        
        rightButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.viewModel!.isOwner.value {
                    strongSelf.settingDidClickBlock?()
                } else {
                    strongSelf.messageDidClickBlock?(strongSelf.viewModel.model.model!)
                }
            }.disposed(by: disposeBag)
        
        editButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if !strongSelf.viewModel.isEditing.value == false {
                    if strongSelf.viewModel.isAboutEditing.value == true {
                        strongSelf.aboutEditButton.sendActions(for: .touchUpInside)
                    }
                    if strongSelf.viewModel.isInterestsEditing.value == true {
                        strongSelf.tagsEditButton.sendActions(for: .touchUpInside)
                    }
                }
                strongSelf.viewModel.isEditing.accept(!strongSelf.viewModel.isEditing.value)
            }.disposed(by: disposeBag)
        
        tagsEditButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.tagsEditButton.isSelected = !strongSelf.tagsEditButton.isSelected
                strongSelf.viewModel.isInterestsEditing.accept(strongSelf.tagsEditButton.isSelected)
                if strongSelf.tagsEditButton.isSelected {
                    strongSelf.tagsEditButton.isHidden = true
//                    strongSelf.tagsEditButton.setTitle("Done", for: .normal)
//                    strongSelf.tagsEditButton.setImage(nil, for: .normal)
                    strongSelf.tagTextField.isHidden = false
                    strongSelf.tagsStackViewHeight.constant += 70
                    strongSelf.tagTextField.becomeFirstResponder()
                    
                } else {
                    strongSelf.viewModel.updateTags { (result, error) in
                        if let error = error {
                            Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                    strongSelf.tagsEditButton.isHidden = false
//                    strongSelf.tagsEditButton.setTitle("Edit", for: .normal)
//                    strongSelf.tagsEditButton.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
                    strongSelf.tagTextField.isHidden = true
                    strongSelf.tagErrorLabel.isHidden = true
                    strongSelf.tagsStackViewHeight.constant -= 70
                    strongSelf.endEditing(true)
                }
                
                strongSelf.contentSizeDidChangeBlock?()
            }.disposed(by: disposeBag)
        
        aboutEditButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                
                if strongSelf.aboutTextView.isFirstResponder {
                    DispatchQueue.main.async {
                        strongSelf.aboutTextView.resignFirstResponder()
                    }                    
                    return
                }
                
                let isEditing = strongSelf.viewModel.isAboutEditing.value
                strongSelf.aboutEditButton.setTitle(!isEditing ? "CANCEL" : "EDIT", for: .normal)
                strongSelf.viewModel.isAboutEditing.accept(!isEditing)
                if !isEditing {
                    strongSelf.aboutPlaceHolderLabel.isHidden = true
                    strongSelf.aboutValueLabel.isHidden = true
                    strongSelf.aboutTextViewBaseView.isHidden = false
                    strongSelf.aboutTextView.becomeFirstResponder()
                } else {
                    strongSelf.viewModel.updateAbout { (result, error) in
                        if let error = error {
                            Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                    strongSelf.aboutPlaceHolderLabel.isHidden = !strongSelf.viewModel.about.value.isEmpty
                    strongSelf.aboutValueLabel.isHidden = false
                    strongSelf.aboutTextViewBaseView.isHidden = true
                    
                }
                strongSelf.layoutIfNeeded()
                strongSelf.contentSizeDidChangeBlock?()
            }.disposed(by: disposeBag)
        
        tagsCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                if strongSelf.viewModel.isInterestsEditing.value {
                    strongSelf.deleteTag(strongSelf.viewModel.tags.value[indexPath.row])
                }
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension ProfileHeaderTableViewCell {
    
    private func deleteTag(_ tag: TagCellViewModel) {
        let defaultAction = UIAlertAction(title: "Delete",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.viewModel.deleteTag(tag)
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to delete this tag?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        Globals.topViewController.present(alert, animated: true) {
            
        }
    }
    
    private func configureTextField() {
        tagTextField.delegate = self
        tagTextField.clearButtonMode = .always
        tagsTextFieldControllerUnderline = MDCTextInputControllerUnderline(textInput: tagTextField)
        tagsTextFieldControllerUnderline.setupStyles(with: tagTextField, observer: self)
        tagTextField.addInputAccessoryView(with: self, doneAction: #selector(self.tagDoneDidClicked))
        tagTextField.font = Styles.customFontLight(15)
        
        aboutTextView.delegate = self
        aboutTextView.font = Styles.customFontLight(15)
        aboutTextView.autocorrectionType = .default
        aboutTextView.addObserver(self, forKeyPath: "contentSize", options: (NSKeyValueObservingOptions.new), context: nil)
    }
    
    @objc private func tagDoneDidClicked() {
        _ = addAsTag(true)
        tagsEditButton.sendActions(for: .touchUpInside)
        tagDoneDidClickBlock?()
    }
    
    private func configureButtons() {
        if viewModel.isFollowing.value != nil {
            leftButton.isHidden = false
            rightButton.isHidden = false
        }
    }
    
    private func configureTagCollectionView() {
        tagCollectionViewHeight.constant = 0
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 8
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 8
    }
    
    private func addAsTag(_ dismissKeyword: Bool = false) -> Bool {
        if let tag = tagTextField.text, !tag.isEmpty {
            if tag.count > 31 {
                tagErrorLabel.text = "Maximum number of character for 1 tag is 31.".uppercased()
                tagErrorLabel.isHidden = false
                tagsStackViewHeight.constant = 70 + tagsCollectionView.contentSize.height + 14
                contentSizeDidChangeBlock?()
                UIView.setAnimationsEnabled(false)
                tagTextField.resignFirstResponder()
                UIView.setAnimationsEnabled(true)
                return true
            }
            tagErrorLabel.isHidden = true
            var newTags = viewModel.tags.value
            newTags.append(TagCellViewModel(tag: tag))
            viewModel.tags.accept(newTags)
            tagTextField.text = ""
            layoutIfNeeded()
            tagCollectionViewHeight.constant = newTags.isEmpty ? 0 : tagsCollectionView.contentSize.height
            tagsStackViewHeight.constant = 70 + tagsCollectionView.contentSize.height
            contentSizeDidChangeBlock?()
            if !dismissKeyword {
                UIView.setAnimationsEnabled(false)
                DispatchQueue.main.async {
                    self.dummyTextField.becomeFirstResponder()
                    DispatchQueue.main.async {
                        self.tagTextField.becomeFirstResponder()
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {
                            UIView.setAnimationsEnabled(true)
                        })
                    }
                }
            } else {
                tagTextField.resignFirstResponder()
            }
            
            return false
        } else {
            return true
        }
    }
}

// MARK: - KVO
extension ProfileHeaderTableViewCell {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        let newValue = (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height
        
        if newValue != textViewHeight.constant {
            textViewBaseViewHeight.constant = 48 + (newValue - 37)
            textViewHeight.constant = newValue
            
            contentSizeDidChangeBlock?()
        }
    }
}

// MARK: - UITextFieldDelegate
extension ProfileHeaderTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return addAsTag()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension ProfileHeaderTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(viewModel.tags.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 30)
    }
}

// MARK - UITextViewDelegate
extension ProfileHeaderTableViewCell: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        aboutTextViewPlaceHolder.isHidden = !textView.text.isEmpty
        aboutTextView.isScrollEnabled = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        aboutTextViewBaseView.layer.borderColor = Styles.g797979.cgColor
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        aboutTextView.isScrollEnabled = false
        return true
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        aboutTextViewBaseView.layer.borderColor = Styles.gD8D8D8.cgColor
        viewModel.about.accept(textView.text)
        aboutEditButton.sendActions(for: .touchUpInside)
    }
}
