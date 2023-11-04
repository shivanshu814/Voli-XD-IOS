//
//  CreateItineraryViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MaterialComponents.MaterialTextFields
import SwifterSwift
import CoreLocation
import AVKit
import MobileCoreServices

class CreateItineraryViewController: BaseViewController, ViewModelBased, KeyboardOverlayAvoidable {
    
    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case mapSegue = "MapSegue"
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var privateButton: UIButton!
    @IBOutlet weak var shareContactButton: UIButton!
    @IBOutlet weak var publishButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionPlaceHolder: UILabel!
    @IBOutlet weak var descriptionErrorLabel: UILabel!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var coverImageErrorLabel: UILabel!
    @IBOutlet weak var addActivityButton: UIButton!
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var datePickerBgView: UIView!
    @IBOutlet weak var privateOverlayButton: UIButton!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var descriptionFieldBorderView: UIView!
    @IBOutlet weak var datePickerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var descriptionBaseViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var descriptionTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var descriptionRootBaseViewHeight: NSLayoutConstraint!
    typealias EditFinishedBlock = (Itinerary) -> Void
    var editFinishedBlock: EditFinishedBlock?
    var dkPickerHelper: DKPickerHelper!
    var viewModel: ItineraryViewModel!
    var keyboardHeight: CGFloat = 0
    var keyboardDidShowBlock: (() -> Void)?
    var showedCameraViewAlready = false
    var showedCount = 0
    var isFirst: Bool { return showedCount < 1 }
    var imagePickerController = UIImagePickerController()
    
    deinit {
        removeKeyboardNotification()
        descriptionTextView.removeObserver(self, forKeyPath: "contentSize")
    }
    
}

// MARK: - View Life Cycle
extension CreateItineraryViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()        
        configureTextField()
        if viewModel == nil {            
            let itinerary = Itinerary(activities: [Activity()])
            viewModel = ItineraryViewModel(itinerary: itinerary, isEditing: true)
        }
        configureFooterView()
        configureNavigationBar()
        bindViewModel(viewModel)
        bindAction()
        keyboardDidShowBlock = {[weak self] in
            self?.dismissPickerView()
        }
        addKeyboardNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.updateUser()
//        addKeyboardNotification()
        descriptionTextView.isScrollEnabled = false
        if !showNoPermissionViewIfNeeded() {            
            // show camera view
            if let _ = viewModel.activityViewModels.first, !viewModel.isSaved {
                if Globals.currentUser == nil || !showedCameraViewAlready {
                    showedCameraViewAlready = true
//                    showImageActionSheet()
//                      showCameraView(with: activityViewModel)
                    return
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissKeyboard()
//        NotificationCenter.default.removeObserver(self)
//        removeKeyboardNotification()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier.flatMap(SegueIdentifier.init) else { return }
        
        switch identifier {
        case .mapSegue:
            if let index = sender as? Int {
                let destinationViewController = segue.destination as! UINavigationController
                destinationViewController.hero.isEnabled = true
                destinationViewController.hero.modalAnimationType = .push(direction: .left)
                let mapViewController = destinationViewController.viewControllers.first as! MapViewController
                mapViewController.viewModel = MapViewModel(itineraryViewModel: viewModel, selectedActivityIndex: index, isEditing: true)                
                mapViewController.addActivityBlock = {[weak self] in                    
                    self?.addActivityButton.sendActions(for: .touchUpInside)
                }
                destinationViewController.modalPresentationStyle = .fullScreen
            }
        }
    }
    
}

// MARK: - RX
extension CreateItineraryViewController {
    
    func bindViewModel(_ viewModel: ItineraryViewModel) {
        
        viewModel.coverImageError
            .asObservable()
            .bind {[weak self] (error) in
                self?.coverImageErrorLabel.text = error?.uppercased()
                self?.coverImageErrorLabel.isHidden = error == nil || error!.isEmpty
        }.disposed(by: disposeBag)
        
        viewModel.heroImageThumbnail
            .asObservable()
            .bind {[weak self] (thumbnail) in
                self?.selectImageButton.imageView?.contentMode = .scaleAspectFill
                if thumbnail == nil || thumbnail!.isEmpty {
                    self?.selectImageButton.setImage(#imageLiteral(resourceName: "Select"), for: .normal)
                    self?.changeImageButton.isHidden = true
                    self?.selectImageButton.isUserInteractionEnabled = true
                } else {
                    self?.loadImage()
                    self?.changeImageButton.isHidden = false
                    self?.changeImageButton.setTitle(viewModel.isVideo ? "Change video" : "Change image", for: .normal)
                    self?.selectImageButton.isUserInteractionEnabled = false
                }
        }.disposed(by: disposeBag)

        (descriptionTextView.rx.text.orEmpty <-> viewModel.descriptionFieldViewModel.value)
            .disposed(by: disposeBag)
        
        viewModel.descriptionFieldViewModel.value
            .asObservable()
            .bind {[weak self] (description) in
                self?.descriptionPlaceHolder.isHidden = !description.isEmpty
        }.disposed(by: disposeBag)
        
        viewModel.descriptionFieldViewModel.errorValue
            .asDriver()
            .map{$0?.uppercased()}
            .drive(descriptionErrorLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.locationViewModel.cityCenter
            .asObservable()
            .filterNil()
            .bind {[weak self] (cityCenter) in
                if cityCenter.coordinate.latitude == 0 && cityCenter.coordinate.longitude == 0 {
                    print("Fail to get the center of location")
                }
                self?.save()
        }.disposed(by: disposeBag)
        
        viewModel.rows
            .asObservable()
            .bind {[weak self] (rows) in
                if self?.viewModel.isReload == true {
                    self?.tableView.reloadData()
                } else {
                    self?.viewModel.isReload = true
                    self?.tableView.insertRows(at: [IndexPath(row: rows.count-1, section: 0)], with: .none)                    
                }
        }.disposed(by: disposeBag)
        
        viewModel.isPrivate
            .asDriver()
            .drive(privateButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        viewModel.isAllowContact
            .asDriver()
            .drive(shareContactButton.rx.isSelected)
            .disposed(by: disposeBag)
        
    }
    
    func bindAction() {
                
        deleteButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.deleteItinerary()
        }.disposed(by: disposeBag)
        
        selectImageButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
//                strongSelf.showImagesSelectionPage(strongSelf.viewModel)
                strongSelf.showCoverActionSheet()
        }.disposed(by: disposeBag)
        
        changeImageButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
//                strongSelf.showImagesSelectionPage(strongSelf.viewModel)
                strongSelf.showCoverActionSheet()
        }.disposed(by: disposeBag)
        
        
        privateOverlayButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.privateButton.sendActions(for: .touchUpInside)
            }.disposed(by: disposeBag)
        
        shareContactButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.updateContactStatus()
            }.disposed(by: disposeBag)
        
        privateButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.updatePrivateStatus()
            }.disposed(by: disposeBag)
        
        publishButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                self?.showLoading()
                if strongSelf.viewModel.validate() {
                    self?.viewModel.getCityCenter()
                    strongSelf.updateFooterLayout()
                    strongSelf.tableView.update()
                } else {
                    self?.stopLoading()
                    strongSelf.updateFooterLayout()
                    strongSelf.tableView.update()
                    if strongSelf.viewModel.firstErrorRow == 0 {
                        strongSelf.tableView.scrollToBottom(animated: true)
                    } else {
                        let indexPath = IndexPath(row: strongSelf.viewModel.firstErrorRow-1, section: 0)
                        strongSelf.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                }
                
            }.disposed(by: disposeBag)
        
        saveButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.isPrivate.accept(true)
                strongSelf.publishButton.sendActions(for: .touchUpInside)
            }.disposed(by: disposeBag)
        
        cancelButton.rx.tap
                    .bind{ [weak self] in
                        guard let strongSelf = self else { return }                        
                        strongSelf.showDiscardChangeAlert()
                    }.disposed(by: disposeBag)
        
        addActivityButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.addActivity()
                strongSelf.updateActivitiesSorting()
            }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension CreateItineraryViewController {
    
    private func deleteItinerary() {
        let defaultAction = UIAlertAction(title: "Delete",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            if strongSelf.viewModel.isSaved {
                                                strongSelf.showLoading()
                                                strongSelf.viewModel.delete {[weak self] (result, error) in
                                                    strongSelf.stopLoading()
                                                    if let error = error {
                                                        self?.showAlert(title: "Error", message: error.localizedDescription)
                                                    }
                                                    else {
                                                        strongSelf.dismiss(animated: false) {
                                                            var newItinerary = strongSelf.viewModel.model
                                                            newItinerary.isDeleted = true
                                                            NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": newItinerary])
                                                        }
                                                    }
                                                }
                                            } else {
                                                strongSelf.viewModel.reset()
                                            }
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to delete this itinerary?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) { }
    }
    
    private func configureFooterView() {
        let isSave = viewModel.isSaved
        cancelButton.isHidden = !isSave
        saveButton.isHidden = isSave
        publishButton.setTitle(isSave ? "Save" : "Publish", for: .normal)
    }
    
    private func setupDkPickerHelper(_ activityViewModel: ActivityViewModel) {
        let vm = CameraViewModel(activityViewModel: activityViewModel)
        dkPickerHelper = DKPickerHelper(target: self, viewModel: vm, completionBlock: {[weak self] viewModel in
            guard let strongSelf = self else { return }
            strongSelf.showLoading("Compassing images...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                strongSelf.stopLoading()
                strongSelf.dkPickerHelper.processAssets()
                if activityViewModel.isAttachmentsUpdated.value {
                    strongSelf.viewModel.selectedActivity = viewModel.activityViewModel
                    strongSelf.updateActivitiesSorting()                    
                }
            })
        })
        dkPickerHelper.configureAttachmentDirectory()
    }
    
    private func setupVideoDkPickerHelper() {
        let vm = CameraViewModel()
        vm.isVideo = true
        dkPickerHelper = DKPickerHelper(target: self, viewModel: vm, completionBlock: {[weak self] viewModel in
            guard let strongSelf = self else { return }
            strongSelf.showLoading("Compassing video...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                strongSelf.dkPickerHelper.processAssets {[weak self] (url, thumbnail) in
                    DispatchQueue.main.async {
                        self?.stopLoading()
                        self?.viewModel.isVideo = true
                        self?.viewModel.heroImage.accept(url)
                        self?.viewModel.heroImageThumbnail.accept(thumbnail)
                        
                    }
                }
            })
        })
        dkPickerHelper.configureAttachmentDirectory()
    }
    
    private func loadImage() {
        if let imageURL = viewModel.heroImageThumbnail.value {
            selectImageButton.loadImage(imageURL)
        }
    }
    
    private func save() {
        viewModel.uploadPhotos { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            strongSelf.stopLoading()
            if let error = error {
                strongSelf.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                strongSelf.viewModel.clearLocalCache()
                if strongSelf.editFinishedBlock != nil {
                    strongSelf.editFinishedBlock?(strongSelf.viewModel.model)
                    strongSelf.dismiss(animated: true, completion: nil)
                } else {
                    
                    strongSelf.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    strongSelf.showItineraryDetailPage(ItineraryDetailViewModel(itinerary: strongSelf.viewModel.model), isJustCreated: true)
                    strongSelf.viewModel.reset()
                }
            }
        }
    }
    
    private func addCancelButton() {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "Cancel_gray"), for: .normal)
        button.contentMode = .center
        button.frame = CGRect(x: 0, y: 0, width: 37, height: 40)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @objc private func cancel() {
        Globals.rootViewController.setSelectIndex(from: 2, to: Globals.rootViewController.lastIndex)
    }
    
    override func dismissPage() {
        showDiscardChangeAlert()
    }
    
    private func showDiscardChangeAlert() {
        let defaultAction = UIAlertAction(title: "Sure",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            strongSelf.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        
        let alert = UIAlertController(title: "",
                                      message: "Are you sure to discard all the unsaved changes?",
                                      preferredStyle: .alert)
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) { }
    }
    
    private func updateActivitiesSorting() {
        guard viewModel.activityViewModels.count > 1 else {return}
        let indexes = viewModel.sortActivitiesIfNeeded()
        if indexes.0 != indexes.1 {
            self.viewModel.updateSortedActivities()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                self.tableView.scrollToRow(at: IndexPath(row: indexes.1 + 1, section: 0), at: .top, animated: true)
            }
        }
    }
    
    private func dismissPickerView() {
        doneButton.setTitleTextAttributes(Styles.toolBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
        datePickerBgView.isHidden = true
        datePickerViewBottom.constant = -309        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        if viewModel.selectedActivity != nil {
            updateActivitiesSorting()
        }
        viewModel.selectedActivity = nil
    }
    
    private func configureNavigationBar() {
        title = viewModel.isSaved ? "Edit itinerary" : "Create itinerary"
        navigationController?.isNavigationBarHidden = false
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
        if viewModel.isSaved {
            addCloseButton()
        } else {
            addCancelButton()
        }
    }
    
    private func configureTableView() {        
        tableView.register(nibWithCellClass: TextFieldTableViewCell.self)
        tableView.estimatedRowHeight = 437
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 124, right: 0)
        tableView.dataSource = self
    }
    
    private func configureTextField() {
        descriptionTextView.isScrollEnabled = true
        descriptionTextView.delegate = self
        descriptionTextView.addObserver(self, forKeyPath: "contentSize", options: (NSKeyValueObservingOptions.new), context: nil)
        descriptionTextView.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
    }
    
    private func updateFooterLayout() {
        if let footerView = tableView.tableFooterView {
            footerView.layoutIfNeeded()
            var rect = tableView.tableFooterView!.frame
            rect.size.height = deleteButton.frame.maxY
            footerView.frame = rect
            tableView.tableFooterView = footerView
        }
        
    }
    
    private func takeVideo() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            imagePickerController.delegate = self
                
            present(imagePickerController, animated: true, completion: nil)
        }
        else {
            print("Camera is not available")
        }
    }

    private func showCameraView(_ activityViewModel: ActivityViewModel, showPhotoLibrary: Bool = false) {
        let cameraViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.viewModel = CameraViewModel(activityViewModel: activityViewModel)
        cameraViewController.showPhotoLibrary = showPhotoLibrary
        let navCtrl = UINavigationController(rootViewController: cameraViewController)
        navCtrl.isNavigationBarHidden = true
        navCtrl.modalPresentationStyle = .fullScreen
        present(navCtrl, animated: true, completion: nil)
    }
    
    private func showImageActionSheet(_ activityViewModel: ActivityViewModel) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        
        
        let takePhotoAction = UIAlertAction(title: "Take photo",
                                       style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        strongSelf.showCameraView(activityViewModel)
        }
        
        let libraryAction = UIAlertAction(title: "Choose from library",
                                            style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.setupDkPickerHelper(activityViewModel)
                                                strongSelf.dkPickerHelper.showCameraRoll()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    strongSelf.showSnackbar("Select up to 9 images", duration: .short)
                                                }
                                                
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
                
        alertController.addAction(takePhotoAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc override func dismissPopup() {
        super.dismissPopup()
        Globals.rootViewController.selectLastIndex()
    }
    
    private func showCoverActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        
        
        let takePhotoAction = UIAlertAction(title: "Cover image",
                                       style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        strongSelf.showImagesSelectionPage(strongSelf.viewModel)
        }
        
        let libraryAction = UIAlertAction(title: "Cover video",
                                            style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.showCoverVideoActionSheet()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
                
        alertController.addAction(takePhotoAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func showCoverVideoActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        
        
        let takePhotoAction = UIAlertAction(title: "Take video",
                                       style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        strongSelf.takeVideo()
        }
        
        let libraryAction = UIAlertAction(title: "Choose from library",
                                            style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.setupVideoDkPickerHelper()
                                                strongSelf.dkPickerHelper.showCameraRoll()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
                
        alertController.addAction(takePhotoAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - IBAction
extension CreateItineraryViewController {
    @IBAction func dateDidChange(_ sender: UIDatePicker) {
        if sender.datePickerMode == .time {
            viewModel.selectedActivity?.date.accept(sender.date.hhmma)
        } else {
            viewModel.selectedActivity?.timeSpend.accept(sender.countDownDuration)
        }
    }
    
    @IBAction override func dismissKeyboard() {
        super.dismissKeyboard()
        dismissPickerView()
    }
    
}

// MARK: - KVO
extension CreateItineraryViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newValue = 94 + (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height - 33
        if newValue != descriptionRootBaseViewHeight.constant {
            descriptionRootBaseViewHeight.constant = newValue
            descriptionTextViewHeight.constant = (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height
            updateFooterLayout()
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension CreateItineraryViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationItem.rightBarButtonItem?.setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
    }
}

// MARK: - UITableViewDataSource
extension CreateItineraryViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = viewModel.rows.value[indexPath.row]
        let index = indexPath.row
        if element is RequiredFieldViewModel  {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! TextFieldTableViewCell
            cell.bindViewModel(viewModel.rows.value[index] as! RequiredFieldViewModel)
            cell.textField.autocorrectionType = .default
            cell.contentSizeDidChangeBlock = {[weak self] in
                self?.tableView.update()
            }
            cell.textField.tag = index
            cell.textField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
            if !viewModel.isSaved && isFirst && Globals.currentUser != nil  {
                cell.textField.becomeFirstResponder()
                showedCount += 1
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CreateActivityTableViewCell", for: IndexPath(row: index, section: 0)) as! CreateActivityTableViewCell
            cell.hideHeader(index != 1)
            let vm = viewModel.rows.value[index] as! ActivityViewModel
            cell.indexLabel.text = String(vm.index + 1)
            cell.bindViewModel(vm)
            
            cell.dateDidChangeBlock = { [weak self] viewModel in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.selectedActivity = viewModel
            }
            
            cell.locationButtonDidClickBlock = { [weak self] viewModel in
                guard let strongSelf = self else { return }

            
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                strongSelf.performSegue(withIdentifier: SegueIdentifier.mapSegue.rawValue, sender: viewModel.index)
            }
            cell.contentSizeDidChangeBlock = {[weak self] in
                self?.tableView.update()
            }
            cell.attachmentDidClickBlock = {[weak self] activityViewModel in
                guard let strongSelf = self else { return }
                strongSelf.showImageActionSheet(activityViewModel)
            }
            
            cell.attachmentDidDeleteBlock = {[weak self] attachmentViewModel in
                guard let strongSelf = self else { return }
                if let thumbnail = strongSelf.viewModel.heroImageThumbnail.value, !thumbnail.isEmpty {
                    if attachmentViewModel.attachment.thumbnail == thumbnail {
                        strongSelf.viewModel.heroImageThumbnail.accept(nil)
                        strongSelf.viewModel.heroImage.accept(nil)
                    }                    
                }
            }
                cell.deleteButtonDidClickBlock = {[weak self] index in
                guard let strongSelf = self else { return }
                strongSelf.dismissPickerView()
                strongSelf.viewModel.removeActivity(index)                
            }
            cell.timeButtonDidClickBlock = {[weak self] activityViewModel in
                guard let strongSelf = self else { return }
                strongSelf.dismissKeyboard()
                strongSelf.viewModel.selectedActivity = activityViewModel
                strongSelf.datePickerView.datePickerMode = .time
                strongSelf.datePickerView.date = activityViewModel.date.value
                strongSelf.datePickerBgView.isHidden = false
                strongSelf.datePickerViewBottom.constant = 0
                UIView.animate(withDuration: 0.2) {
                    strongSelf.view.layoutIfNeeded()
                }
            }
            cell.timeSpendButtonDidClickBlock = {[weak self] activityViewModel in
                guard let strongSelf = self else { return }
                strongSelf.dismissKeyboard()
                strongSelf.viewModel.selectedActivity = activityViewModel
                strongSelf.datePickerView.minuteInterval = 1
                strongSelf.datePickerView.datePickerMode = .countDownTimer
                let timeSpend = Int(activityViewModel.timeSpend.value)
                
                let calendar : NSCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                                        
                let dateComp : NSDateComponents = NSDateComponents()
                if timeSpend != 0 {
                    dateComp.hour = timeSpend / (60*60)
                    dateComp.minute = (timeSpend % (60*60)) / 60
                } else {
                    dateComp.hour = 1
                    dateComp.minute = 0
                }
                
                let date = calendar.date(from: dateComp as DateComponents)!
                
                let defaulDateComp : NSDateComponents = NSDateComponents()
                defaulDateComp.hour = 0
                defaulDateComp.minute = dateComp.minute == 1 ? 2 : 1
                let defaultDate = calendar.date(from: defaulDateComp as DateComponents)!
                
                strongSelf.datePickerView.setDate(defaultDate, animated: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    strongSelf.datePickerView.setDate(date, animated: false)
                })
                
                // update textfield
                if activityViewModel.timeSpend.value == 0 {
                    activityViewModel.timeSpend.accept(60*60)
                }
                
                // show picker
                strongSelf.datePickerBgView.isHidden = false
                strongSelf.datePickerViewBottom.constant = 0
                UIView.animate(withDuration: 0.2) {
                    strongSelf.view.layoutIfNeeded()
                }
            }
            cell.tagDoneDidClickBlock = {[weak self] in
                self?.dismissKeyboard()
            }
            return cell
        }
    }
    
}

// MARK: - UITextViewDelegate
extension CreateItineraryViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textView.isScrollEnabled = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        descriptionFieldBorderView.layer.borderColor = Styles.g797979.cgColor
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        descriptionFieldBorderView.layer.borderColor = Styles.gD8D8D8.cgColor
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.isScrollEnabled = false
        return true
    }
       
}

// MARK: - UINavigationControllerDelegate, UIImagePickerControllerDelegate
extension CreateItineraryViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let selectedVideo:URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) {
            let selectorToCall = #selector(self.videoSaved(_:didFinishSavingWithError:context:))
                          
            UISaveVideoAtPathToSavedPhotosAlbum(selectedVideo.relativePath, self, selectorToCall, nil)
            // Save the video to the app directory
            let videoData = try? Data(contentsOf: selectedVideo)
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
            let dataPath = documentsDirectory.appendingPathComponent("video.mp4")
            try! videoData?.write(to: dataPath, options: [])
                        
            let asset = AVURLAsset(url: dataPath)
            showLoading("Compassing video...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                asset.processVideoAssets() {[weak self] (path, thumbnail) in
                    DispatchQueue.main.async {
                        self?.stopLoading()
                        self?.viewModel.isVideo = true
                        self?.viewModel.heroImage.accept(path)
                        self?.viewModel.heroImageThumbnail.accept(thumbnail)
                    }
                }
            })
            
        }
        
        picker.dismiss(animated: true)
    }
    
    @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer){
        if let theError = error {
            print("error saving the video = \(theError)")
        } else {
           DispatchQueue.main.async(execute: { () -> Void in
           })
        }
    }
}
