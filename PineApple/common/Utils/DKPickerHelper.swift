//
//  DKPickerHelper.swift
//  PineApple
//
//  Created by Tao Man Kit on 6/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import DKImagePickerController
import Photos

class DKPickerHelper {

    // MARK: - Properties
    var dkPicker: DKImagePickerController!
    var target: UINavigationControllerDelegate
    var viewModel: CameraViewModel
    typealias CompletionBlock = (CameraViewModel) -> Void
    var completionBlock: CompletionBlock?
    
    // MARK: - Init
    init(target: UINavigationControllerDelegate, viewModel: CameraViewModel, completionBlock: CompletionBlock? = nil) {
        self.target = target
        self.viewModel = viewModel
        self.completionBlock = completionBlock
    }

    
}

// MARK: - Public
extension DKPickerHelper {
    func showCameraRoll() {
        setupDkPicker()
        let assets = (viewModel.attachments.value
            .filter{$0.asset != nil})
            .map{$0.asset}
        if !assets.isEmpty {
            dkPicker.select(assets: assets as! [DKAsset])
        }
        
        dkPicker.modalPresentationStyle = .fullScreen
        (target as! UIViewController).present(dkPicker, animated: true, completion: nil)
    }
    
    func configureAttachmentDirectory() {
        let path = "\(SEARCH_PATH)/Attachments"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                // Attempt to create folder
                try fileManager.createDirectory(atPath: path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                // Creation failed. Print error & return nil
                print(error.localizedDescription)
            }
        }
    }
        
    
    func processAssets(_ completionHandler: ((String, String) -> Void)? = nil) {
        if viewModel.isVideo {
            guard let asset = viewModel.avAsset else {
                completionHandler?("", "")
                return
            }
            asset.processVideoAssets(completionHandler)
        } else {
            if let activityViewModel = viewModel.activityViewModel, (activityViewModel.attachments.value.count + viewModel.attachments.value.count) > 10 {
                (target as! UIViewController).showSnackbar("You can have maximum of 9 photos in an activity")
                return
            }
            
            var newAttachments = [Attachment]()
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            var index = 0
            for var attachment in viewModel.attachments.value {
                if let asset = attachment.asset, attachment.path.isEmpty {
                    asset.fetchOriginalImage(options: options, completeBlock: {(initialImage, info) in
                        if initialImage != nil, let paths = saveImageForUpload(initialImage!, suffix: attachmentIndex, isProfile: false) {
                            attachment.path = paths.path
                            attachment.thumbnail = paths.thumbnail
                            newAttachments.append(attachment)
                        }
                    })
                    attachmentIndex += 1
                } else {
                    newAttachments.append(attachment)
                }
                index += 1
            }
            viewModel.attachments.accept(newAttachments)
            
            var newAttachmentVMs = viewModel.activityViewModel!.attachments.value
            var loop = newAttachmentVMs.count
            index = viewModel.activityViewModel!.index
            let vm = viewModel.attachments.value.map{ (attachment) -> AttachmentViewModel in
                let vm = AttachmentViewModel(attachment: attachment, indexPath: index < 0 ? nil : IndexPath(row: loop, section: index))
                loop += 1
                return vm
            }
            
            newAttachmentVMs.insert(contentsOf: vm, at: newAttachmentVMs.count-1)
            viewModel.activityViewModel!.attachments.accept(newAttachmentVMs)
            viewModel.activityViewModel!.isAttachmentsUpdated.accept(true)
            
        }
        
    }
}

// MARK: - Private
extension DKPickerHelper {
        
    func setupDkPicker() {
        let isSingleSelect = viewModel.isSingleUpload || viewModel.isUploadProfile
        configureAttachmentDirectory()
        dkPicker = DKImagePickerController()
        dkPicker.showsCancelButton = true
        dkPicker?.singleSelect = isSingleSelect
        dkPicker.sourceType = .photo
        dkPicker.assetType = viewModel.isVideo ? .allVideos : .allPhotos
        dkPicker.UIDelegate = CustomUIDelegate()
        dkPicker.didSelectAssets = {[weak self] (assets: [DKAsset]) in
            guard let strongSelf = self else { return }

            if assets.isEmpty { return }

            if isSingleSelect {
                if strongSelf.viewModel.isVideo {
                    let options = PHVideoRequestOptions()
                    options.isNetworkAccessAllowed = true
                    assets.first?.fetchAVAsset(options: options, completeBlock: { (asset, info) in
                        if let urlAsset = asset as? AVURLAsset {
                            strongSelf.viewModel.avAsset = urlAsset
                            DispatchQueue.main.async {
                                strongSelf.completionBlock?(strongSelf.viewModel)
                            }
                            
                        }
                    })
                } else {
                    let options = PHImageRequestOptions()
                    options.isNetworkAccessAllowed = true
                    options.isSynchronous = true
                    assets.first?.fetchOriginalImage(options: options, completeBlock: {(initialImage, info) in
                        if initialImage != nil, let paths = saveImageForUpload(initialImage!) {
                            strongSelf.viewModel.paths.accept(paths)
                        }
                    })
                }
            } else {
                var newAttachments = strongSelf.viewModel.attachments.value
                let addedAssets = (newAttachments.filter{$0.asset != nil}).map{$0.asset}
                for asset in assets {
                    if addedAssets.contains(asset) {
                        continue
                    }
                    if asset.type == .photo {
                        let attachment = Attachment(asset: asset)
                        newAttachments.append(attachment)
                        attachmentIndex += 1
                    }
                }
                strongSelf.viewModel.attachments.accept(newAttachments)
                strongSelf.completionBlock?(strongSelf.viewModel)
                
            }
        }
        
        dkPicker.delegate = target
    }
    
}
