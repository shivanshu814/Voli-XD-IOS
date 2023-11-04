//
//  CreateActivityTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import GooglePlaces
import MaterialComponents.MaterialTextFields
import SwifterSwift

class CreateActivityTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var timeButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timeSpendButton: UIButton!
    @IBOutlet weak var timeSpendErrorLabel: UILabel!
    @IBOutlet weak var attachmentErrorLabel: UILabel!
    @IBOutlet weak var timeSpendTextField: UITextField!
    
    @IBOutlet weak var tagTextFieldBoarderView: UIView!
    @IBOutlet weak var tagErrorLabel: UILabel!
    @IBOutlet weak var tagsFieldBaseView: UIView!
    @IBOutlet weak var headerTop: NSLayoutConstraint!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsFieldBaseViewHeight: NSLayoutConstraint!
    
    var sizingCell: TagCollectionViewCell!
    var viewModel: ActivityViewModel!
    private var disposeBag = DisposeBag()
    typealias LocationButtonDidClickBlock = (ActivityViewModel) -> Void
    var locationButtonDidClickBlock: LocationButtonDidClickBlock?
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    typealias TagContentSizeDidChangeBlock = () -> Void
    var tagContentSizeDidChangeBlock: TagContentSizeDidChangeBlock?
    typealias AttachmentDidClickBlock = (ActivityViewModel) -> Void
    var attachmentDidClickBlock: AttachmentDidClickBlock?
    typealias DeleteButtonDidClickBlock = (Int) -> Void
    var deleteButtonDidClickBlock: DeleteButtonDidClickBlock?
    typealias TimeButtonDidClickBlock = (ActivityViewModel) -> Void
    var timeButtonDidClickBlock: TimeButtonDidClickBlock?
    typealias DateDidChangeBlock = (ActivityViewModel) -> Void
    var dateDidChangeBlock: DateDidChangeBlock?
    typealias TimeSpendButtonDidClickBlock = (ActivityViewModel) -> Void
    var timeSpendButtonDidClickBlock: TimeSpendButtonDidClickBlock?
    typealias TagDoneDidClickBlock = () -> Void
    var tagDoneDidClickBlock: TagDoneDidClickBlock?
    typealias AttachmentDidDeleteBlock = (AttachmentViewModel) -> Void
    var attachmentDidDeleteBlock: AttachmentDidDeleteBlock?
    
    var tapGR: UITapGestureRecognizer!
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTextField()
        configureLayout()
        configureAttachmentCollectionView()
        configureTagCollectionView()
        configureTapGuesture()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        hideHeader(false)
        timeTextField.text = ""
        disposeBag = DisposeBag()
    }

}

// MARK: - RX
extension CreateActivityTableViewCell {
    
    func bindViewModel(_ viewModel: ActivityViewModel) {
        self.viewModel = viewModel        
        
        viewModel.isAttachmentValid.asDriver()
            .drive(attachmentErrorLabel.rx.isHidden)
            .disposed(by: disposeBag)
                
        viewModel.isTimeSpendValid.asDriver()
            .drive(timeSpendErrorLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.isLocationValid
            .asObservable()
            .bind {[weak self] (isLocationValid) in
                if !isLocationValid {
                    let attributedString = NSAttributedString(string: "LOCATION*", attributes:  [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                                                                 NSAttributedString.Key.foregroundColor: UIColor(hex: 0xFF3A7A)!,
                                                                                                                 NSAttributedString.Key.font: Styles.customFontBold(11)])
                    self?.locationButton.setAttributedTitle(attributedString, for: .normal)
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.attachments
            .bind(to: collectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
        }.disposed(by: disposeBag)
        
        viewModel.isAttachmentsUpdated
            .asObservable()
            .bind {[weak self] (isUpdated) in
                guard let strongSelf = self else { return }
                if isUpdated {
                    strongSelf.updateAttachmentLayout()
                    strongSelf.contentSizeDidChangeBlock?()
                    DispatchQueue.main.async {
                        strongSelf.viewModel.isAttachmentsUpdated.accept(false)
                    }
                    
                }
        }
        .disposed(by: disposeBag)
        
        viewModel.locationString
            .asObservable()
            .bind {[weak self] (locationString) in
                guard let strongSelf = self else { return }
                let attributedString = NSAttributedString(string: locationString.isEmpty ? "LOCATION*" : locationString.uppercased(), attributes:  [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                                                                                                      NSAttributedString.Key.foregroundColor: (strongSelf.viewModel.isLocationValid.value ? Styles.p6A0DFF : UIColor(hex: 0xFF3A7A)!),
                NSAttributedString.Key.font: Styles.customFontBold(11)])
                strongSelf.locationButton.setAttributedTitle(attributedString, for: .normal)
        }
        .disposed(by: disposeBag)
        
        viewModel.date
            .asObservable()
            .bind {[weak self] (date) in
                guard let strongSelf = self else { return }
                                
                strongSelf.dateDidChangeBlock?(strongSelf.viewModel)
                strongSelf.timeTextField.text = Styles.dateFormatter_HHmma.string(from: date.hhmma).lowercased()
                
        }
        .disposed(by: disposeBag)
        
        viewModel.tags
            .bind(to: tagsCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
            cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        viewModel.timeSpend
            .asDriver()
            .map{ $0.toString == "0 min" ? "" : $0.toString }
            .drive(timeSpendTextField.rx.text)
            .disposed(by: disposeBag)
        
        updateAttachmentLayout()
        updateTagsLayout()
        bindAction()
    }
    
    func bindAction() {
        
        timeSpendButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.timeSpendButtonDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        timeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.timeButtonDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        locationButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.locationButtonDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                if indexPath.row == strongSelf.viewModel.attachments.value.count-1 {
                    strongSelf.attachmentDidClickBlock?(strongSelf.viewModel)
                } else {
                    strongSelf.deleteAttachment(strongSelf.viewModel.attachments.value[indexPath.row])
                }
            }.disposed(by: disposeBag)
        
        tagsCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.deleteTag(strongSelf.viewModel.tags.value[indexPath.row])
            }.disposed(by: disposeBag)
        
        deleteButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.deleteActivity()
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Public
extension CreateActivityTableViewCell {
    func hideHeader(_ isHidden: Bool) {
        headerView.isHidden = isHidden
        headerTop.constant = isHidden ? -51 : 0
    }
}

// MARK: - Private
extension CreateActivityTableViewCell {
        
    private func deleteTag(_ tag: TagCellViewModel) {
        let defaultAction = UIAlertAction(title: "Delete",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.viewModel.deleteTag(tag)
                                            strongSelf.tagErrorLabel.isHidden = true
                                            strongSelf.layoutIfNeeded()
                                            strongSelf.updateTagsLayout()
                                            strongSelf.contentSizeDidChangeBlock?()
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in
                                            
        }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to delete this tag?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        Globals.topViewController.present(alert, animated: true) {
            
        }
    }
    
    private func deleteActivity() {
        let defaultAction = UIAlertAction(title: "Delete",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
//                                            if strongSelf.viewModel.index == 0 {
//                                                strongSelf.viewModel.setup(with: Activity())
//                                                strongSelf.tagCollectionViewHeight.constant = 0
//                                                strongSelf.viewModel.isAttachmentsUpdated.accept(true)
//                                                strongSelf.contentSizeDidChangeBlock?()
//                                            } else {
                                                strongSelf.deleteButtonDidClickBlock?(strongSelf.viewModel.index)
//                                            }
                                            
                                            
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in
                                            
        }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to delete this Activity?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        Globals.topViewController.present(alert, animated: true) {
            
        }
    }
    
    public func configureLayout() {
        timeSpendErrorLabel.text = timeSpendErrorLabel.text?.uppercased()
        attachmentErrorLabel.text = attachmentErrorLabel.text?.uppercased()
    }
    
    private func deleteAttachment(_ attachment: AttachmentViewModel) {        
        let defaultAction = UIAlertAction(title: "Delete",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.viewModel.deleteAttachment(attachment)
                                            strongSelf.updateAttachmentLayout()
                                            strongSelf.contentSizeDidChangeBlock?()
                                            strongSelf.attachmentDidDeleteBlock?(attachment)
                                            
                                            
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in
                                            
        }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to delete this photo?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        Globals.topViewController.present(alert, animated: true) {
            
        }
    }
    
    private func configureTextField() {
        tagsTextField.configureLayout()
        tagsTextField.delegate = self
        tagsTextField.addInputAccessoryView(with: self, doneAction: #selector(self.tagDoneDidClicked))
        
        
        timeTextField.configureLayout()
        timeTextField.delegate = self
        timeTextField.addInputAccessoryView(with: self, doneAction: #selector(self.tagDoneDidClicked))
        
        timeSpendTextField.configureLayout()
        timeSpendTextField.delegate = self
        timeSpendTextField.addInputAccessoryView(with: self, doneAction: #selector(self.tagDoneDidClicked))
                        
    }
    
    private func configureAttachmentCollectionView() {
        collectionView.register(nibWithCellClass: AttachmentCollectionViewCell.self)
        collectionView.delegate = self
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 12
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 12
    }
    
    private func configureTagCollectionView() {
        tagCollectionViewHeight.constant = 0
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
    }
    
    @objc private func tagDoneDidClicked() {
        _ = addAsTag(true)
        tagDoneDidClickBlock?()
    }
    
    private func updateTagsLayout() {
        tagsTextField.placeholder = viewModel.tags.value.isEmpty ? "" : ""
        configureTextField()
        layoutIfNeeded()
        tagCollectionViewHeight.constant = viewModel.tags.value.isEmpty ? 0 : tagsCollectionView.contentSize.height
        let space: CGFloat = viewModel.tags.value.isEmpty ? 0 : 10
        tagsFieldBaseViewHeight.constant = 48 + space + tagsCollectionView.contentSize.height
    }
    
    private func updateAttachmentLayout() {
        let attachments = viewModel.attachments.value
        let h = (UIScreen.main.bounds.width-56)/3
        var rowCount = CGFloat(Int(attachments.count/3))
        if attachments.count%3 > 0 && rowCount < 3 {
            rowCount += 1
        }
        collectionViewHeight.constant = min(h * 3 + (16 * 2), h * rowCount + 16 * (rowCount-1))
    }
    
    private func addAsTag(_ dismissKeyword: Bool = false) -> Bool {
        if let tag = tagsTextField.text, !tag.isEmpty {
            if tag.count > 31 {
                tagErrorLabel.text = "Maximum number of character for 1 tag is 31.".uppercased()
                tagErrorLabel.isHidden = false
                contentSizeDidChangeBlock?()
                UIView.setAnimationsEnabled(false)
                tagsTextField.resignFirstResponder()
                UIView.setAnimationsEnabled(true)
                return true
            } else if viewModel.tags.value.count == 7 {
                tagErrorLabel.text = "Maximum number of tags for 1 activity is 7.".uppercased()
                tagErrorLabel.isHidden = false
                contentSizeDidChangeBlock?()
                UIView.setAnimationsEnabled(false)
                tagsTextField.resignFirstResponder()
                UIView.setAnimationsEnabled(true)
                return true
            }
                        
            tagErrorLabel.isHidden = true
            var newTags = viewModel.tags.value
            newTags.append(TagCellViewModel(tag: tag))
            viewModel.tags.accept(newTags)
            tagsTextField.text = ""
            layoutIfNeeded()
            updateTagsLayout()
            contentSizeDidChangeBlock?()
            if !dismissKeyword {
//                UIView.setAnimationsEnabled(false)
//                DispatchQueue.main.async {
//                    self.dummyTextField.becomeFirstResponder()
//                    DispatchQueue.main.async {
//                        self.tagsTextField.becomeFirstResponder()
//                        DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {
//                            UIView.setAnimationsEnabled(true)
//                        })
//                    }
//                }
            } else {
                tagsTextField.resignFirstResponder()
            }            
            
            return false
        } else {
            return true
        }
    }
    
    private func configureTapGuesture() {
        tapGR = UITapGestureRecognizer(target: self, action: #selector(self.tagBaseViewDidTap))
        tapGR.cancelsTouchesInView = false
        tapGR.delaysTouchesBegan = false
        tagsCollectionView.addGestureRecognizer(tapGR)
    }
    
    @objc private func tagBaseViewDidTap() {
        tagsTextField.becomeFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension CreateActivityTableViewCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tagTextFieldBoarderView.layer.borderColor = Styles.g797979.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        _ = addAsTag()
        tagTextFieldBoarderView.layer.borderColor = Styles.gD8D8D8.cgColor
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return addAsTag()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension CreateActivityTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            let wh = (UIScreen.main.bounds.width-56)/3
            return CGSize(width: wh, height: wh)
        } else {
            sizingCell.bindViewModel(viewModel.tags.value[indexPath.row])
            let size = sizingCell.cellSize
            return CGSize(width: min(collectionView.width, size.width) , height: 32)
        }
    }
}

// MARK - UITextViewDelegate
extension CreateActivityTableViewCell: UITextViewDelegate {
        
    
    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel.description.accept(textView.text)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            viewModel.description.accept("")
        }
    }
    
}

