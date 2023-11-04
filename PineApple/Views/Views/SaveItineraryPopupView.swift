//
//  SaveItineraryPopupView.swift
//  PineApple
//
//  Created by Tao Man Kit on 2/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SaveItineraryPopupView: UIView, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var popupBaseView: UIView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var textFieldBorderView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var itierneraryTitleLabel: UILabel!
    @IBOutlet weak var durationLocationLabel: UILabel!
    @IBOutlet weak var cellViewTop: NSLayoutConstraint!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    var superViewController: UIViewController?
    var sizingCell: TagCollectionViewCell!
    private let disposeBag = DisposeBag()
    typealias CompletionBlock = () -> Void
    var completionBlock: CompletionBlock?
    
    var viewModel: SavedCollectionViewModel! {
        didSet {
            bindViewModel(viewModel)
            bindAction()
            doneButton.isUserInteractionEnabled = false
            viewModel.getCollectionList {[weak self] (result, error) in
                self?.doneButton.isUserInteractionEnabled = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableView()
        configureTagCollectionView()
        configureTextField()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configureButtons()
    }
}

// MARK: - RX
extension SaveItineraryPopupView {
    
    func bindViewModel(_ viewModel: SavedCollectionViewModel) {
        
        titleLabel.text = viewModel.mode.title
        
        doneButton.isHidden = viewModel.mode == .delete
        cancelButton.isHidden = viewModel.mode != .delete
        yesButton.isHidden = viewModel.mode != .delete
        
        nameTextField.placeholder = viewModel.collectionName.value
        (nameTextField.rx.text.orEmpty <-> viewModel.collectionName).disposed(by: disposeBag)        
        
        if let path = viewModel.itineraryViewModel?.activityViewModels.first?.attachments.value.first? .attachment.path {
            imageView.loadImage(path)
        }
        
        viewModel.itineraryViewModel?.title
            .asDriver()
            .drive(itierneraryTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        if let model = viewModel.model {
            Observable.combineLatest(model.timeSpend, model.model.activityViewModels.first!.locationString) { (x, y) -> String in
                return x + " • " + y
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (timeLocation) in
                guard let strongSelf = self else { return }
                strongSelf.durationLocationLabel.text = timeLocation
            })
                .disposed(by: disposeBag)
        }
        
        viewModel.collections
            .bind(to: tableView.rx.items(cellIdentifier: "OptionTableViewCell", cellType: OptionTableViewCell.self)) { (row, element, cell) in
                cell.titleLabel.text = element.name
        }.disposed(by: disposeBag)
                
        viewModel.collectionName.asObservable()
            .bind {[weak self] text in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.search()
        }
        .disposed(by: disposeBag)
        
        viewModel.model?.tags
            .bind(to: tagsCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                cell.enableNoBoarderStyle()
        }.disposed(by: disposeBag)
        
        if viewModel.mode == .add || viewModel.mode == .rename {
            nameTextField.becomeFirstResponder()
            titleLabel.isHidden = viewModel.mode != .rename
            headerLabel.isHidden = false
        } else {
            headerLabel.isHidden = true
            textFieldBorderView.isHidden = true
            titleLabel.isHidden = false
        }
    }
    
    func bindAction() {
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                strongSelf.viewModel.collectionName.accept(strongSelf.viewModel.collections.value[indexPath.row].name)
                strongSelf.nameTextField.resignFirstResponder()
        }.disposed(by: disposeBag)
        
        doneButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.superViewController?.showLoading()
                strongSelf.viewModel.save { (result, error) in
                    strongSelf.superViewController?.stopLoading()
                    if let error = error {
                        print(error.localizedDescription)
                        Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        strongSelf.dismissButton.sendActions(for: .touchUpInside)
                        strongSelf.completionBlock?()
                    }
                }
        }.disposed(by: disposeBag)
        
        yesButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.superViewController?.showLoading()
                strongSelf.viewModel.delete { (result, error) in
                    strongSelf.superViewController?.stopLoading()
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        strongSelf.dismissButton.sendActions(for: .touchUpInside)
                        strongSelf.completionBlock?()
                    }
                }
        }.disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dismissButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension SaveItineraryPopupView {
    
    private func configureTableView() {
        tableView.register(UINib(nibName: "OptionTableViewCell", bundle: nil), forCellReuseIdentifier: "OptionTableViewCell")
    }
    
    private func configureTextField() {
        nameTextField.addInputAccessoryView(with: Globals.rootViewController, doneAction: #selector(Globals.rootViewController.dismissKeyboard))
    }
    
    private func configureButtons() {

    }
    
    private func configureTagCollectionView() {
        
        tagsCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagsCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        sizingCell.enableNoBoarderStyle()
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (tagsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
    }
}

// MARK: - UITextFieldDelegate
extension SaveItineraryPopupView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        tableView.isHidden = viewModel.collections.value.isEmpty || viewModel.mode == .rename
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        tableView.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButton.sendActions(for: .touchUpInside)
        return true
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension SaveItineraryPopupView : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizingCell.bindViewModel(viewModel.model!.tags.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 29)
    }
}
