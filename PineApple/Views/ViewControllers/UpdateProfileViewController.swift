//
//  UpdateProfileViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import DKImagePickerController
import Photos
import FBSDKLoginKit
import FirebaseAuth
import TTGSnackbar

class UpdateProfileViewController: BaseViewController, ViewModelBased, KeyboardOverlayAvoidable {
    
    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case signInSegue = "SignInSegue"
        case locationSegue = "LocationSegue"
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var privateButton: UIButton!
    @IBOutlet weak var privateOverlayButton: UIButton!    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var textFieldBaseView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    var fbLoginButton: FBLoginButton!
    var viewModel: ProfileViewModel!    
    var dkPicker: DKImagePickerController?
    var keyboardHeight: CGFloat = 0
    var keyboardDidShowBlock: (() -> Void)?
    private let footerHeight: CGFloat = 136
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationbar()
        ProfileViewModel.configureProfileDirectory()
        configureTextField()
        Globals.configureProfileDirectory()
        configureTableView()
        bindViewModel(viewModel)
        bindAction()
        addKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier.flatMap(SegueIdentifier.init) else { return }
        
        switch identifier {
        case .locationSegue:
            let destinationViewController = segue.destination as! SelectLocationViewController
            destinationViewController.placeSelectionAction = { [weak self] location in
                self?.viewModel.updateLocation(location)
            }
        default: break
        }
    }
    
}

// MARK: - RX
extension UpdateProfileViewController {
    
    func bindViewModel(_ viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        
        viewModel.isPrivate
            .asDriver()
            .drive(privateButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        (nameTextField.rx.text.orEmpty <-> viewModel.name.value).disposed(by: disposeBag)
        
        viewModel.name.errorValue
            .asObservable()
            .bind {[weak self] (error) in
                self?.errorLabel.isHidden = error == nil || error!.isEmpty
                self?.errorLabel.text = error?.uppercased()
        }.disposed(by: disposeBag)
        
        viewModel.thumbnail
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (url) in
                guard let strongSelf = self else { return }
                strongSelf.loadImage()
            }).disposed(by: disposeBag)
        
        viewModel.rows
            .bind(to: tableView.rx.items) { tableView, index, element in
                if element is ColumnTextFieldViewModel {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ColumnTextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! ColumnTextFieldTableViewCell
                    cell.bindViewModel(viewModel.rows.value[index] as! ColumnTextFieldViewModel)
                    cell.textField.isSecureTextEntry = true
                    cell.rightTextField.isSecureTextEntry = true
                    cell.textField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                    cell.rightTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                    return cell
                    //                } else if index == 5 {
                    //                    let cell = tableView.dequeueReusableCell(withIdentifier: "ColumnTextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! ColumnTextFieldTableViewCell
                    //                    cell.bindViewModel(viewModel.rows.value[index] as! ColumnTextFieldViewModel)
                    //                    cell.singleLineTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                    //                    cell.rightSingleLineTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                    //                    cell.singleLineTextField.keyboardType = .numberPad
                    //                    cell.rightSingleLineTextField.keyboardType = .numberPad
                    //                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! TextFieldTableViewCell
                    cell.bindViewModel(viewModel.rows.value[index])
                    cell.textField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                    if element.title == "LOCATION" {
                        cell.textField.isUserInteractionEnabled = false
                        cell.textField.clearButtonMode = .never
                        cell.dropDownButton.isHidden = false
                        cell.dropDownDidChangeBlock = {[weak self] in
                            self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                            self?.performSegue(withIdentifier: SegueIdentifier.locationSegue.rawValue, sender: nil)
                        }
                    } else if index == 1 {
                        cell.textField.keyboardType = .emailAddress
                    }
                    return cell
                }
            }.disposed(by: disposeBag)
        
        viewModel.rows
            .asObservable()
            .bind {[weak self] (rows) in
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        
        cancelButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        
        editProfileButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showImageActionSheet()
            }.disposed(by: disposeBag)
        
        
        saveButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.save { (result, error) in
                    strongSelf.stopLoading()
                    if result {
                        strongSelf.showSnackbar("Your changes are saved")
                    } else {
                        if let error = error {
                            strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
                self?.tableView.update()
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
            }.disposed(by: disposeBag)
        
        privateButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.updatePrivateStatus()
            }.disposed(by: disposeBag)
        
        privateOverlayButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.privateButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension UpdateProfileViewController {
    
    private func setupDkPicker() {        
        dkPicker = nil
        dkPicker = DKImagePickerController()
        dkPicker?.showsCancelButton = true
        dkPicker?.singleSelect = true
        dkPicker?.sourceType = .photo
        dkPicker?.assetType = .allPhotos
        dkPicker?.UIDelegate = CustomUIDelegate()
        dkPicker?.didSelectAssets = {[weak self] (assets: [DKAsset]) in
            guard let strongSelf = self else { return }
            
            if assets.isEmpty {
                return
            }
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            assets.first?.fetchOriginalImage(options: options, completeBlock: {(initialImage, info) in
                if initialImage != nil, let paths = saveImageForUpload(initialImage!) {
                    strongSelf.updateProfileImage(paths)
                }
            })
            
        }
        
        dkPicker?.delegate = self
    }
    
    private func updateProfileImage(_ paths: (path: String, thumbnail: String)) {
        showLoading()
        // upload
        ProfileViewModel.upload(path: paths.path, thumbnail: paths.thumbnail, completionHandler: { [weak self] (success, urls) in
            guard let strongSelf = self else { return }
            if let urls = urls {
                strongSelf.viewModel.profileImageUrl.accept(urls.path)
                strongSelf.viewModel.thumbnail.accept(urls.thumbnail)
                
                // Update
                strongSelf.viewModel.saveProfileImage { (result, error) in
                    strongSelf.stopLoading()
                    if let error = error {
                        strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        strongSelf.loadImage()
                    }
                }
            } else {
                strongSelf.stopLoading()
                strongSelf.showAlert(title: "Error", message: "Upload fail")
            }
        })
    }
    
    private func configureNavigationbar() {
        title = "My profile"
        addBackButton()
    }
    
    private func configureTextField() {
        nameTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: TextFieldTableViewCell.self)
        tableView.register(nibWithCellClass: ColumnTextFieldTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        
    }
    
    private func showImageActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        let removeAction = UIAlertAction(title: "Remove current photo",
                                         style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.showLoading()
                                            strongSelf.viewModel.removeImage()
                                            strongSelf.viewModel.saveProfileImage {[weak self] (result, error) in
                                                self?.stopLoading()
                                                if let error = error {
                                                    self?.showAlert(title: "Error", message: error.localizedDescription)
                                                } else {
                                                    self?.loadImage()
                                                }
                                            }
        }
        
        let takePhotoAction = UIAlertAction(title: "Take photo",
                                       style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        let cameraViewModel = CameraViewModel(profileViewModel: strongSelf.viewModel)
                                        strongSelf.showCameraView(cameraViewModel)
                                        
        }
        
        let libraryAction = UIAlertAction(title: "Choose from library",
                                            style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.setupDkPicker()
                                                if let picker = strongSelf.dkPicker {
                                                    picker.modalPresentationStyle = .fullScreen
                                                    strongSelf.present(picker, animated: true, completion: nil)
                                                }
        }
        
        let fbAction = UIAlertAction(title: "Import from facebook",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.showLoading()
                                            strongSelf.setupDkPicker()
                                            let user = Auth.auth().currentUser
                                            if let user = user, let id = user.providerData.first?.uid, let url = URL(string: "https://graph.facebook.com/\(id)/picture?type=large") {
                                                    
                                                if let data = try? Data(contentsOf: url), let image = UIImage(data: data), let paths = saveImageForUpload(image) {
                                                    strongSelf.updateProfileImage(paths)
                                                }
                                            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        
        alertController.addAction(removeAction)
        alertController.addAction(takePhotoAction)
        alertController.addAction(libraryAction)
        if !Globals.currentUser!.fbId.isEmpty {
            alertController.addAction(fbAction)
        }
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
        
    private func loadImage() {
        if viewModel.thumbnail.value == nil || viewModel.thumbnail.value!.isEmpty {
            profileImageView.image = nil
        } else {
            profileImageView.loadImage(viewModel.thumbnail.value!)
        }
    }
    
    private func updateFooterHeightIfNeeded() {
        let offsetY = view.frame.height - (tableView.frame.origin.y + (tableView.contentSize.height - tableView.tableFooterView!.frame.height + footerHeight))
        var rect = tableView.tableFooterView!.frame
        if offsetY > 0 {
            rect.size.height = footerHeight + offsetY
        } else {
            rect.size.height = footerHeight
        }
        tableView.tableFooterView!.frame = rect
        
    }
}

// MARK - UINavigationControllerDelegate
extension UpdateProfileViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationItem.rightBarButtonItem?.setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
    }
    
}

// MARK - UITextFieldDelegate
extension UpdateProfileViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldBaseView.layer.borderColor = Styles.g797979.cgColor
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldBaseView.layer.borderColor = Styles.gD8D8D8.cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.name.value.accept("")
        return true
    }
}
