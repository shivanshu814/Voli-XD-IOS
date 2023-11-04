//
//  ATCChatThreadViewController.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/26/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import UIKit
import Photos
import Firebase
import MessageKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseDynamicLinks
import InputBarAccessoryView
import RxCocoa
import RxSwift

struct ATCChatUIConfiguration {
    let primaryColor: UIColor
    let secondaryColor: UIColor
    let inputTextViewBgColor: UIColor
    let inputTextViewTextColor: UIColor
    let inputPlaceholderTextColor: UIColor
}

class ATCChatThreadViewController: MessagesViewController, MessagesDataSource, MessageInputBarDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    var user: ATCUser
    private var messages: [ATChatMessage] = []
    private var messageListener: ListenerRegistration?
    
    private let db = Firestore.firestore()
    private var reference: CollectionReference?
    private let storage = Storage.storage().reference()
    private let paging = Paging(start: 1, itemPerPage: 20)
    private var isFirstLoad = true
    
    private var isSendingPhoto = false
    
    var channel: ATCChatChannel
    var uiConfig: ATCChatUIConfiguration
    let remoteData = ATCRemoteData()
    
    var dkPickerHelper: DKPickerHelper!
    var cameraViewModel = CameraViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    
    init(user: ATCUser, channel: ATCChatChannel, uiConfig: ATCChatUIConfiguration) {
        self.user = user
        self.channel = channel
        self.uiConfig = uiConfig
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        messageListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        addBackButton()
        
        Globals.configureProfileDirectory()
        
        cameraViewModel.paths
            .asObservable()
            .filterNil()
            .bind {[weak self] (paths) in
                self?.sendPhoto(paths.path)
        }
        .disposed(by: disposeBag)
        
        if !channel.id.isEmpty {
            reference = db.collection(["channels", channel.id, "thread"].joined(separator: "/"))
            remoteData.checkPath(path: ["channels", channel.id, "thread"], dbRepresentation: channel.representation)
            
            messageListener = reference?
                .order(by: "created", descending: true)
                .limit(to: 20)
                .addSnapshotListener {[weak self] querySnapshot, error in
                    guard let strongSelf = self else { return }
                    guard let snapshot = querySnapshot else {
                        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                        return
                    }
                    
                    strongSelf.readChannel()
                    
                    if strongSelf.isFirstLoad {
                        if let document = snapshot.documentChanges.last?.document {
                            strongSelf.paging.lastDocumentSnapshot = document
                        } else {
                            strongSelf.paging.lastDocumentSnapshot = nil
                            strongSelf.paging.isMore.accept(false)
                        }
                    }
                    
                    snapshot.documentChanges.forEach { change in
                        strongSelf.handleDocumentChange(change)
                    }
                    
                    
            }
            
        }
        
        navigationItem.largeTitleDisplayMode = .never
        self.title = channel.name
        
        maintainPositionOnKeyboardFrameChanged = true
        
        let inputTextView = messageInputBar.inputTextView
        inputTextView.tintColor = uiConfig.primaryColor
        inputTextView.textColor = uiConfig.inputTextViewTextColor
        inputTextView.backgroundColor = uiConfig.inputTextViewBgColor
        inputTextView.layer.cornerRadius = 6.0
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.borderColor = Styles.g797979.cgColor
//        inputTextView.font = Styles.customFontLight(15)
        inputTextView.typingAttributes = Styles.multipleLineTextAttributes
        
        inputTextView.placeholderLabel.textColor = uiConfig.inputPlaceholderTextColor
        inputTextView.placeholderLabel.text = "Start typing..."
        inputTextView.placeholderLabel.font = Styles.customFontLight(15)
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 6, right: 12)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 15, bottom: 6, right: 15)
        
        
        let sendButton = messageInputBar.sendButton
        sendButton.setTitleColor(uiConfig.primaryColor, for: .normal)
        sendButton.setImage(UIImage.localImage("share-icon", template: true), for: .normal)
        sendButton.title = ""
        sendButton.setSize(CGSize(width: 55, height: 30), animated: false)
        sendButton.tintColor = Styles.p8437FF
        
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 100, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 100, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
        layout?.setMessageOutgoingAccessoryViewPosition(.messageBottom)
        
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = UIColor(hex: 0x8C8C8C)
        cameraItem.image = UIImage.localImage("camera-filled-icon", template: true)
        cameraItem.addTarget(
            self,
            action: #selector(cameraButtonPressed),
            for: .primaryActionTriggered
        )
        cameraItem.setSize(CGSize(width: 50, height: 30), animated: false)
        
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 55, animated: false)
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
        messageInputBar.backgroundColor = UIColor(hex: 0xF6F7F8)
        messageInputBar.backgroundView.backgroundColor = UIColor(hex: 0xF6F7F8)
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.padding = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        messageInputBar.middleContentViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        
        showLoading()
        User.findById(channel.recipient.uid!) {[weak self] (user, error) in
            self?.stopLoading()
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self?.channel.token = user!.token
                self?.user.voliUser = user
            }
        }
        
        messagesCollectionView.messageCellDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readChannel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Actions
    
    @objc private func cameraButtonPressed() {
        showImageActionSheet()
        
//        let picker = UIImagePickerController()
//        picker.delegate = self
//
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            picker.sourceType = .camera
//        } else {
//            picker.sourceType = .photoLibrary
//        }
//        picker.modalPresentationStyle = .fullScreen
//        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    
    
    private func showImageActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        
        
        let takePhotoAction = UIAlertAction(title: "Take photo",
                                       style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        strongSelf.showCameraView(strongSelf.cameraViewModel)
        }
        
        let libraryAction = UIAlertAction(title: "Choose from library",
                                            style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.setupDkPickerHelper()
                                                strongSelf.dkPickerHelper.showCameraRoll()
                                                
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in
                                            
        }
                
        alertController.addAction(takePhotoAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func setupDkPickerHelper() {
        dkPickerHelper = DKPickerHelper(target: self, viewModel: cameraViewModel, completionBlock: {[weak self] (paths) in
            guard let strongSelf = self else { return }
            
        })
        
        dkPickerHelper.configureAttachmentDirectory()
    }
    
    private func readChannel() {
        if !channel.id.isEmpty {
            remoteData.readChannel(path: ["channels", channel.id], userIndex: channel.userIndex)
        }
    }
    
    private func save(_ message: ATChatMessage) {
        print("saving message: \(message.representation)")
        
        func send(_ message: ATChatMessage) {
            reference?.addDocument(data: message.representation) {[weak self] error in
                guard let strongSelf = self else { return }
                if let e = error {
                    print("Error sending message: \(e.localizedDescription)")
                    return
                }
                
                let content = message.image == nil ? message.content : "Photo"
                strongSelf.remoteData.updateChannel(path: ["channels", strongSelf.channel.id], message: content, date: message.sentDate, userIndex: strongSelf.channel.userIndex)
                if let currentUser = Globals.currentUser, let recipient = strongSelf.user.voliUser {
                    if !strongSelf.channel.token.isEmpty && recipient.isPrivateMessageEnabled {
                        PushNotificationManager.shared.sendPushNotification(to: strongSelf.channel.token, title: "", body: "\(currentUser.displayName) sent you a message.", data: ["channel" : strongSelf.channel.id])
                    }
                    self?.messagesCollectionView.scrollToBottom()
                }
            }
        }
        
        if reference == nil {
            remoteData.checkPath(path: ["channels", channel.id, "thread"], dbRepresentation: channel.representation) {[weak self] (id, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    strongSelf.reference = strongSelf.db.collection(["channels", id!, "thread"].joined(separator: "/"))
                        
                    strongSelf.channel.id = id!
                    strongSelf.messageListener = strongSelf.reference?
                        .order(by: "created", descending: true)
                        .addSnapshotListener { [weak self] querySnapshot, error in
                        guard let strongSelf = self else { return }
                        guard let snapshot = querySnapshot else {
                            print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                            return
                        }
                        strongSelf.paging.isMore.accept(false)
                        snapshot.documentChanges.forEach { change in
                            strongSelf.handleDocumentChange(change)
                        }
                    }
                    send(message)
                }
            }
        } else {
            send(message)
        }
    }
    
    private func insertNewMessage(_ message: ATChatMessage) {
        guard !messages.contains(message) else {
            return
        }
        
        messages.append(message)
        messages.sort()
        
        let isLatestMessage = messages.index(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let message = ATChatMessage(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            insertNewMessage(message)
        default:
            break
        }
    }
    
    private func uploadImage(_ path: String, to channel: ATCChatChannel, completion: @escaping (String?) -> Void) {
            
        ProfileViewModel.upload(path: path, completionHandler: { (success, url) in
            if !success {
                completion(nil)
                return
            }
            completion(url)
            
        })
        
    }
    
    private func sendPhoto(_ path: String) {
        print("is sending photo")
        showLoading()
        isSendingPhoto = true
        let image = UIImage(contentsOfFile: path)!
        
        uploadImage(path, to: channel) { [weak self] url in
            self?.stopLoading()
            guard let strongSelf = self else { return }
            guard let `self` = self else {
                print("upload image to channel with failed")
                return
            }
            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
            let mediaItem = ATCMediaItem(url: URL(string: url), image: image, placeholderImage: image, size: image.size)
            let message = ATChatMessage(
                                        messageKind: MessageKind.photo(mediaItem),
                                        createdAt: Date(),
                                        atcSender: strongSelf.user,
                                        recipient: strongSelf.channel.recipient,
                                        seenByRecipient: false)
            message.downloadURL = url
            self.save(message)
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    func currentSender() -> SenderType {
        return Sender(id: user.initials, displayName: user.fullName())
    }
    
    // MARK: - MessagesDataSource
    func currentSender() -> Sender {
        return Sender(id: user.uid ?? "noid", displayName: "You")
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        if indexPath.section < messages.count {
            return messages[indexPath.section]
        }
        
        return ATChatMessage(user: self.user, image: UIImage.localImage("camera-icon", template: true))
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType,
                                    at indexPath: IndexPath) -> NSAttributedString? {
        
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
    
    open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        print(indexPath.section)
        if indexPath.section == 0 && paging.isMore.value {
            if isFirstLoad {
                isFirstLoad = false
                return
            }
            
            remoteData.getMessages(channel, paging: paging) {[weak self] (newMessages, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    strongSelf.showAlert(title: "error", message: error.localizedDescription)
                } else {
                    strongSelf.paging.start += 1
                    strongSelf.messages.append(contentsOf: newMessages!)
                    strongSelf.messages.sort()
                    strongSelf.messagesCollectionView.reloadData()
                }
                
            }
        }
    }
}

// MARK: - MessageCellDelegate
extension ATCChatThreadViewController: MessageCellDelegate {
    func didSelectURL(_ url: URL) {
        print(url.absoluteString)
        DynamicLinks.dynamicLinks().handleUniversalLink(url) { (dynamicLink, error) in
            if let url = dynamicLink?.url {
                (UIApplication.shared.delegate as! AppDelegate).handleDynamicLink(url)
            }
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            print(indexPath)
            let message = messages[indexPath.section]
            if let downloadURL = message.downloadURL, !message.downloadURL!.isEmpty {
                let _vc = UIStoryboard(name: "ImageViewer", bundle: nil).instantiateInitialViewController() as! UINavigationController
                let vc = _vc.viewControllers.first as! ImageViewController
                vc.imageURLString = downloadURL
                vc.view.backgroundColor = UIColor.black
                vc.collectionView!.backgroundColor = UIColor.black
                _vc.modalPresentationStyle = .fullScreen
                present(_vc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - MessagesLayoutDelegate
extension ATCChatThreadViewController: MessagesLayoutDelegate {
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return .zero
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: 0, height: 8)
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath,
                           with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    
}

// MARK: - MessageInputBarDelegate
extension ATCChatThreadViewController {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

        let textKind = MessageKind.attributedText(NSAttributedString(string: text, attributes: Styles.multipleLineTextAttributes))
        let message = ATChatMessage(
                                    messageKind: textKind,
                                    createdAt: Date(),
                                    atcSender: user,
                                    recipient: channel.recipient,
                                    seenByRecipient: false)
        save(message)
        inputBar.inputTextView.text = ""
    }
}

// MARK: - MessagesDisplayDelegate

extension ATCChatThreadViewController: MessagesDisplayDelegate {    
    
//    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        switch message.kind {
//        case .text(let text):
//            return NSAttributedString(string: text, attributes: [
//                .foregroundColor: Styles.g504F4F,
//                .font: Styles.customFontLight(15)
//            ])
//        default: return nil
//        }
//    }
    
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        switch message.kind {
        case .photo(let mediaItem):
            if mediaItem.image == nil {
                imageView.loadImage(mediaItem.url!.absoluteString)
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
            }
        default: break
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url]
    }
    
//    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
//        return
//    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? uiConfig.primaryColor : uiConfig.secondaryColor
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) -> Bool {
        return false
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        //    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        return .custom { (view) in
            view.layer.cornerRadius = 6
            view.layer.masksToBounds = false
        }
        //    return .bubble
        //    return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if let message = message as? ATChatMessage {
            avatarView.initials = message.atcSender.initials
            if let urlString = message.atcSender.profilePictureURL {
                avatarView.loadImage(urlString)
                //        avatarView.kf.setImage(with: URL(string: urlString))
            }
        }
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return Styles.g504F4F
    }
    
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if let message = message as? ATChatMessage {
            let dateStr = message.sentDate.toDateTimeString
            
            if let label = (accessoryView.subviews.filter{$0 is UILabel}).first as? UILabel {
                label.text = dateStr
                label.textAlignment = message.atcSender.uid == Globals.currentUser?.id ? .right : .left
            } else {
                let _label = UILabel(text: dateStr)
                _label.font = Styles.customFontBold(11)
                _label.textColor = UIColor(hex: 0x8F8F8F)
                _label.sizeToFit()
                _label.frame = CGRect(x: 0, y: accessoryView.frame.height-_label.bounds.height, width: accessoryView.frame.width, height: _label.bounds.height)
                _label.textAlignment = message.atcSender.uid == Globals.currentUser?.id ? .right : .left
                accessoryView.addSubview(_label)
            }
        }
    }
    
}
