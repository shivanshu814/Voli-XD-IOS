//
//  CameraViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import Photos
import RxCocoa
import RxSwift
import SwifterSwift
import CoreLocation

var attachmentIndex = 0

class CameraViewController: UIViewController, UINavigationControllerDelegate {

    // MARK: - Properties
    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var countBaseView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var noPermissionView: UIView!
    @IBOutlet weak var createProfileButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
    private var dkPickerHelper: DKPickerHelper!
    private let cameraController = CameraController()
    var viewModel: CameraViewModel!
    var showPhotoLibrary = false
    private let disposeBag = DisposeBag()
    override var prefersStatusBarHidden: Bool { return true }
    
}

// MARK: - View Life Cycle
extension CameraViewController {
    
    override func viewDidLoad() {
        LocationController.shared.startUpdatingLocation()
        configureNavigationBar()
        styleCaptureButton()
        configureCameraController()
        setupDkPickerHelper()
        bindViewModel(viewModel)
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noPermissionView.isHidden = Globals.currentUser != nil
        if Globals.currentUser == nil {
            noPermissionView.blur()
            return
        }
        if showPhotoLibrary {
            dkPickerHelper.showCameraRoll()
            showPhotoLibrary = false
        }
    }
    
}

// MARK: - RX
extension CameraViewController: ViewModelBased {
    
    func bindViewModel(_ viewModel: CameraViewModel) {
        self.viewModel = viewModel
        
        viewModel.showPreviewImage
            .asObservable()
            .bind {[weak self] (showPreviewImage) in
                guard let strongSelf = self else { return }
                strongSelf.previewImageView.isHidden = !showPreviewImage
                if showPreviewImage {
                    if let url = strongSelf.viewModel.profileViewModel?.profileImageUrl.value {
                        if let image = UIImage(contentsOfFile: url) {
                            self?.previewImageView.image = image
                        }
                    }
                }
            }.disposed(by: disposeBag)
        
        cameraRollButton.isHidden = viewModel.isUploadProfile || viewModel.isSingleUpload
        
        viewModel.attachments
            .asObservable()
            .bind {[weak self] (attachments) in
                guard let strongSelf = self else { return }
                strongSelf.countBaseView.isHidden = attachments.isEmpty
                strongSelf.countLabel.text = String(attachments.count)
                strongSelf.countBaseView.playBounceAnimation()
            }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        
        loginButton.rx.tap
            .bind{ [weak self] in
                self?.showLoginPage()
            }.disposed(by: disposeBag)
        
        createProfileButton.rx.tap
            .bind{ [weak self] in
                self?.showUserProfileLandingPage()
            }.disposed(by: disposeBag)
        
        browseButton.rx.tap
            .bind{ [weak self] in
                self?.dismiss(animated: false, completion: nil)
                Globals.rootViewController.setSelectIndex(from: 2, to: 0)
            }.disposed(by: disposeBag)
        
        captureButton.rx.tap
            .bind{ [weak self] in
                self?.captureImage()
            }.disposed(by: disposeBag)
        
        toggleFlashButton.rx.tap
            .bind{ [weak self] in
                self?.toggleFlash()
            }.disposed(by: disposeBag)
        
        toggleCameraButton.rx.tap
            .bind{ [weak self] in
                self?.switchCameras()
            }.disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.previewImageView.isHidden {
                    self?.dismiss(animated: true, completion: nil)
                } else if strongSelf.viewModel.isShowingPreview {
                    strongSelf.previewImageView.isHidden = true
                    strongSelf.viewModel.isShowingPreview = false
                    strongSelf.viewModel.currentPath = nil
                } else {
                    let oldUrl = strongSelf.viewModel.profileViewModel?.model?.profileImageUrl
                    strongSelf.viewModel.profileViewModel?.profileImageUrl.accept(oldUrl)
                    strongSelf.previewImageView.isHidden = true
                }
                
            }.disposed(by: disposeBag)
        
        cameraRollButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dkPickerHelper.showCameraRoll()
            }.disposed(by: disposeBag)
        
        doneButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                
                if strongSelf.viewModel.isSingleUpload {
                    strongSelf.viewModel.paths.accept(strongSelf.viewModel.currentPath)
                    strongSelf.dismiss(animated: true, completion: nil)
                } else if strongSelf.viewModel.isUploadProfile {
                    strongSelf.showLoading()
                    if let profileViewModel = strongSelf.viewModel.profileViewModel, let path = profileViewModel.profileImageUrl.value, let thumbnail = profileViewModel.thumbnail.value {
                        ProfileViewModel.upload(path: path, thumbnail: thumbnail, completionHandler: { [weak self] (success, urls) in
                            guard let strongSelf = self else { return }
                            if let urls = urls {
                                strongSelf.viewModel.profileViewModel?.profileImageUrl.accept(urls.path)
                                strongSelf.viewModel.profileViewModel?.thumbnail.accept(urls.thumbnail)
                                // Update
                                strongSelf.viewModel.profileViewModel?.saveProfileImage { (result, error) in
                                    strongSelf.stopLoading()
                                    if let error = error {
                                        strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                                    } else {
                                        strongSelf.dismiss(animated: true, completion: nil)
                                    }
                                }
                            } else {
                                strongSelf.stopLoading()
                                strongSelf.showAlert(title: "Error", message: "Upload fail")
                            }
                        })
                    } else {
                        strongSelf.dismiss(animated: true, completion: nil)
                    }
                }
                
                if strongSelf.viewModel.isShowingPreview {
                    LocationController.shared.startUpdatingLocation()
                    if let paths = strongSelf.viewModel.currentPath {
                        
                        let attachment = Attachment(path: paths.path, thumbnail: paths.thumbnail, identifier: paths.path, location: LocationController.shared.location?.coordinate, date: Date().hhmma)
                        var newAttachments = strongSelf.viewModel.attachments.value
                        newAttachments.append(attachment)
                        strongSelf.viewModel.attachments.accept(newAttachments)
                        strongSelf.viewModel.isShowingPreview = false
                        strongSelf.previewImageView.isHidden = true
                    }
                    return
                }
                
                if strongSelf.viewModel.attachments.value.isEmpty {
                    strongSelf.dismiss(animated: true, completion: nil)
                    return
                }
                                    
                strongSelf.showLoading("Compassing images...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    strongSelf.stopLoading()
                    strongSelf.dkPickerHelper.processAssets()
                    strongSelf.dismiss(animated: true, completion: nil)
                })
                
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension CameraViewController {
    
    private func configureNavigationBar() {
        navigationController?.isNavigationBarHidden = true
    }
    
    private func configureCameraController() {
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
            
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }
    }
    
    private func styleCaptureButton() {
        captureButton.backgroundColor = UIColor.clear
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
    }
    
    private func toggleFlash() {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage( #imageLiteral(resourceName: "FlashOff"), for: .normal)
        } else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage( #imageLiteral(resourceName: "FlashOn"), for: .normal)
        }
    }
    
    private func switchCameras() {
        do {
            try cameraController.switchCameras()
        } catch {
            print(error)
        }
        
        switch cameraController.currentCameraPosition {
        case .some(.front):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "switchCam"), for: .normal)
            
        case .some(.rear):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "switchCam"), for: .normal)
            
        case .none:
            return
        }
    }
    
    private func captureImage() {
        cameraController.captureImage {[weak self](image, error) in
            guard let strongSelf = self else { return }
            guard let image = image else {
                print(error ?? "Image capture error")
                return
            }
                 
            if strongSelf.viewModel.isSingleUpload {
                strongSelf.viewModel.currentPath = saveImageForUpload(image)
                strongSelf.viewModel.showPreviewImage.accept(true)
                strongSelf.previewImageView.image = image
                strongSelf.previewImageView.isHidden = false
                strongSelf.viewModel.isShowingPreview = true
            } else if strongSelf.viewModel.isUploadProfile {
                if let paths = saveImageForUpload(image) {
                    strongSelf.viewModel.profileViewModel?.profileImageUrl.accept(paths.path)
                    strongSelf.viewModel.profileViewModel?.thumbnail.accept(paths.thumbnail)
                    strongSelf.viewModel.showPreviewImage.accept(true)
                }
            } else {
                if let paths = saveImageForUpload(image, suffix: attachmentIndex, isProfile: false) {
                    strongSelf.previewImageView.image = image
                    strongSelf.previewImageView.isHidden = false
                    strongSelf.viewModel.isShowingPreview = true
                    strongSelf.viewModel.currentPath = paths
                    attachmentIndex += 1
                }
                
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
        }
    }
    
    private func setupDkPickerHelper() {
        dkPickerHelper = DKPickerHelper(target: self, viewModel: viewModel)
        dkPickerHelper.configureAttachmentDirectory()
    }
    
}

// MARK: - UINavigationControllerDelegate
extension CameraController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationItem.rightBarButtonItem?.setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
    }
    
}

