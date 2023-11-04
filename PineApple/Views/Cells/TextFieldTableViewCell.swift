//
//  TextFieldTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TextFieldTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties

    @IBOutlet weak var textViewBaseView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewPlaceHolder: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var dropDownButton: UIButton!
    @IBOutlet weak var textFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    
    var viewModel: TextFieldViewModel!
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    typealias DropDownDidChangeBlock = () -> Void
    var dropDownDidChangeBlock: DropDownDidChangeBlock?
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        textFieldHeight.constant = 48
        textField.isSecureTextEntry = false
        textField.isUserInteractionEnabled = true
        dropDownButton.isHidden = true
        textField.keyboardType = .default
        textView.keyboardType = .default        
        textField.autocorrectionType = .no
        disposeBag = DisposeBag()
    }
    
}

// MARK: - Private
extension TextFieldTableViewCell {
    private func configureTextStyles() {
        textField.borderStyle = .none
        textField.font = Styles.customFontLight(15)
        textField.setPlaceHolderTextColor(Styles.g797979)
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
                
        textViewBaseView.borderColor = Styles.gD8D8D8
        textView.font = Styles.customFontLight(15)
        textView.delegate = self
    }
}

// MARK: - RX
extension TextFieldTableViewCell {
    
    func bindViewModel(_ viewModel: TextFieldViewModel) {
        self.viewModel = viewModel

        textField.isHidden = !viewModel.isSingleLine
        textView.isHidden = viewModel.isSingleLine
        textViewPlaceHolder.isHidden = viewModel.isSingleLine
        headerLabel.text = viewModel.title
        textField.placeholder = viewModel.description
        configureTextStyles()
        
        if viewModel.isSingleLine {
            (textField.rx.text.orEmpty <-> viewModel.value).disposed(by: disposeBag)
        } else {
            (textView.rx.text.orEmpty <-> viewModel.value).disposed(by: disposeBag)
        }
        
        
        viewModel.errorValue
            .asObservable()
            .bind {[weak self] (error) in
                guard let strongSelf = self else { return }
                strongSelf.errorLabel.text = error?.uppercased()
                strongSelf.errorLabel.isHidden = error == nil || error!.isEmpty                
        }.disposed(by: disposeBag)
        
        bindAction()
    }
    
    func bindAction() {
        dropDownButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dropDownDidChangeBlock?()
        }.disposed(by: disposeBag)
    }
}

// MARK: - KVO
extension TextFieldTableViewCell {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newValue = 48 + (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height - 33
        
        if newValue != textFieldHeight.constant {
            textFieldHeight.constant = newValue
            textViewHeight.constant = (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height
            
            if !viewModel.isSingleLine {
                contentSizeDidChangeBlock?()
            }
        }
    }
}

// MARK - UITextViewDelegate
extension TextFieldTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel.value.accept(textView.text)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            viewModel.value.accept("")
        }
    }

}

// MARK - UITextFieldDelegate
extension TextFieldTableViewCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textViewBaseView.layer.borderColor = Styles.g797979.cgColor
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        textViewBaseView.layer.borderColor = Styles.gD8D8D8.cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.value.accept("")
        return true
    }
}
