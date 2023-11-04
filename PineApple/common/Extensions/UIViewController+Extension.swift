//
//  UIViewController+Extension.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 2/11/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import NVActivityIndicatorView
import Firebase
import FBSDKLoginKit
import TTGSnackbar
import MessageUI
import MessageKit

extension UIViewController: NVActivityIndicatorViewable {
    
    // MARK: - Show popup component
    
    func showSnackbar(_ message: String, topMargin: CGFloat = 64, duration: TTGSnackbarDuration = .middle) {
        let snackbar = TTGSnackbar(message: message, duration: duration)
        snackbar.backgroundColor = UIColor(hex: 0x9FFAEF)
        snackbar.messageTextColor = Styles.g2E2D2D
        snackbar.messageTextFont = Styles.customFont(17)
        snackbar.topMargin = topMargin
        snackbar.leftMargin = 16
        snackbar.icon = #imageLiteral(resourceName: "check")
        snackbar.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        snackbar.rightMargin = 16
        snackbar.animationType = TTGSnackbarAnimationType.slideFromTopBackToTop
        snackbar.show()
    }
    
    func showLoading(_ message: String = "") {
        view.isUserInteractionEnabled = false
        startAnimating(CGSize(width: 40, height: 40),message: message, messageFont: Styles.customFontBold(14), type: .ballPulseSync, color: Styles.p8437FF, backgroundColor: UIColor.clear, textColor: Styles.p8437FF)
    }
    
    func stopLoading() {
        stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - AddNavigationItem
    
    func addMoreButton() {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "ProfileMoreButton"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.frame = CGRect(x: 0, y: 4, width: 37, height: 40)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
        button.addTarget(self, action: #selector(UIViewController.showActionSheet), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    func addTitleView() {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "VoliXD"), for: .normal)
        button.contentMode = .left
        button.isUserInteractionEnabled = false
        button.frame = CGRect(x: 0, y: 4, width: 107, height: 40)
//        button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    func addBackButton(_ isWhite: Bool = false) {
        if navigationController?.viewControllers.count == 1 {
            addCloseButton()
        } else {
            let button = UIButton(type: .system)
            button.setImage(#imageLiteral(resourceName: isWhite ? "back_white" : "back"), for: .normal)
            button.contentMode = .center
            button.frame = CGRect(x: 0, y: 4, width: 37, height: 40)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)
            button.addTarget(self, action: #selector(UIViewController.goBack), for: .touchUpInside)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        }
    }
    
    func addHeroBackButton() {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "back"), for: .normal)
        button.contentMode = .center
        button.frame = CGRect(x: 0, y: 4, width: 37, height: 40)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(UIViewController.goBackHero), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    func addCloseButton() {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "back"), for: .normal)
        button.contentMode = .center
        button.frame = CGRect(x: -23, y: 4, width: 37, height: 40)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(UIViewController.dismissPage), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    func addProfileButton() {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "profile&settings"), for: .normal)
        button.frame = CGRect(x: 0, y: 4, width: 37, height: 40)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
        button.addTarget(self, action: #selector(UIViewController.showUserProfileLandingPage), for: .touchUpInside)
        button.tintColor = Styles.p8437FF
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem?.tintColor = Styles.p8437FF
    }
    
    // MARK: - Action
    
    @objc func dismissPage() {
        if presentingViewController == nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func showActionSheet() {
        
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func goBackHero() {
        navigationController?.hero.modalAnimationType = .pull(direction: .right)
        navigationController?.hero.dismissViewController()
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @IBAction func dismissKeyboard() {
        view.endEditing(true)
    }
    
//    @IBAction func dismissKeyboard(sender: Any) {
//        view.endEditing(true)
//    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    
    func showLocationPermissionAlert(_ isAccountCreating: Bool) {
        let message = isAccountCreating ? "User's location is required for creating account. Please go to setting and allow the app to access your location while you are using the app." : "To show your current location, please go to setting and allow the app to access your location while you are using the app."
        let alertController = UIAlertController (title: "Alert", message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func showShareActionSheet(url: URL, title: String, type: String) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let shareAction = UIAlertAction(title: "Share with Voli member",
                                              style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.showShareToFollowingUserPage(url, title: title, type: type)
        }
        
        let otherAction = UIAlertAction(title: "Share with others",
                                              style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                let content = "\(title) - Voli XD\n\nUnique experiences starts with Voli XD, find inspirations and adventures nearby or in your next travel destinations around the world.\n\(url.absoluteString)"
                                                let items = [content]
                                                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                                                strongSelf.present(ac, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        alertController.addAction(shareAction)
        alertController.addAction(otherAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func messageButtonDidClicked(_ user: User, title: String? = nil, link: String? = nil, type: String? = nil) {
        if ISENABLED_CHAT {
            showLoading()
            
            ATCRemoteData().getChannelByUser(user) {[weak self] (channel, error) in
                if let error = error {
                    self?.stopLoading()
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    var _channel = channel ?? ATCChatChannel(users: [user, Globals.currentUser!])
                    if link == nil {
                        self?.stopLoading()
                        self?.showChatRoom(_channel)
                    } else {
                        User.findById(user.id) {[weak self] (user, error) in
                            self?.stopLoading()
                            if let error = error {
                                self?.showAlert(title: "Error", message: error.localizedDescription)
                            } else {
                                _channel.token = user!.token
                                let content = "\(title ?? "")]\n\n\(link!)"
                                let textKind = MessageKind.attributedText(NSAttributedString(string: content, attributes: Styles.multipleLineTextAttributes))
                                let message = ATChatMessage(messageKind: textKind, createdAt: Date(),
                                              atcSender: Globals.currentUser!.atcUser,
                                              recipient: _channel.recipient,
                                              seenByRecipient: false)
                                
                                ATCRemoteData().sendMessage(message, channel: _channel, title: title ?? "", type: type ?? "") {[weak self] (result, error) in
                                    self?.stopLoading()
                                    self?.showSnackbar("Shared！")
                                    if let error = error {
                                        self?.showAlert(title: "Error", message: error.localizedDescription)
                                    }
                                }
                            }
                        }
                        
                        
                    }
                }
            }

        } else {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            
            let fbAction = UIAlertAction(title: "Facebook Messager",
                                         style: .default) {[weak self] (action) in
                                            if let url = URL(string: "fb-messenger://user-thread/\(user.fbId)") {
                                                if link != nil {
                                                    UIPasteboard.general.string = link!
                                                    self?.showSnackbar("Copied to clipboard")
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now()+0.8) {
                                                    UIApplication.shared.open(url, options: [:], completionHandler: {
                                                        (success) in
                                                        if success == false {
                                                            // Messenger is not installed. Open in browser instead.
                                                            let url = URL(string: "https://m.me/\(user.fbId)")
                                                            if UIApplication.shared.canOpenURL(url!) {
                                                                UIApplication.shared.open(url!)
                                                            }
                                                        }
                                                    })
                                                }
                                                
                                            }
            }
            
            let mailAction = UIAlertAction(title: "Mail",
                                           style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            if MFMailComposeViewController.canSendMail() {
                                                let mail = MFMailComposeViewController()
                                                mail.mailComposeDelegate = Globals.shared
                                                mail.setToRecipients([user.email])
                                                if link != nil {
                                                    mail.setMessageBody(link!, isHTML: false)
                                                }
                                                strongSelf.present(mail, animated: true)
                                            } else {
                                                strongSelf.showAlert(title: "Error", message: "Cannot send email from this device.")
                                            }
            }
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .cancel) { (action) in }
            
            if !user.fbId.isEmpty {
                alertController.addAction(fbAction)
            }
            alertController.addAction(mailAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            
        }
    }
    
    func showSortPopup(_ itinerariesViewModel: ItinerariesViewModel, completionBlock: LocationPopupView.CompletionBlock? = nil) {
        
        let nib = UINib.init(nibName: "SortPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? SortPopupView {
            popupView.superViewController = self
            popupView.completionBlock = completionBlock
            popupView.viewModel = itinerariesViewModel            
            popupView.sortPopupDismissButton.addTarget(self, action: #selector(UIViewController.dismissPopup), for: .touchUpInside)
            Globals.rootViewController.view.addSubview(popupView)
            popupView.frame = UIScreen.main.bounds
            popupView.alpha = 0.0
            popupView.fadeIn(duration: 0.2, completion: nil)
            popupView.playBounceAnimation([0.6 ,1.1, 1], duration: 0.4)
        }
    }
    
    func showSortPopup(_ suggestionsViewModel: SuggestionsViewModel, completionBlock: LocationPopupView.CompletionBlock? = nil) {
        
        let nib = UINib.init(nibName: "SortPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? SortPopupView {
            popupView.superViewController = self
            popupView.completionBlock = completionBlock
            popupView.suggestionsViewModel = suggestionsViewModel
            popupView.sortPopupDismissButton.addTarget(self, action: #selector(UIViewController.dismissPopup), for: .touchUpInside)
            Globals.rootViewController.view.addSubview(popupView)
            popupView.frame = UIScreen.main.bounds
            popupView.alpha = 0.0
            popupView.fadeIn(duration: 0.2, completion: nil)
            popupView.playBounceAnimation([0.6 ,1.1, 1], duration: 0.4)
        }
    }
    
    func showLocationPopup(_ itinerariesViewModel: ItinerariesViewModel, completionBlock: LocationPopupView.CompletionBlock? = nil) {
        
        let nib = UINib.init(nibName: "LocationPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? LocationPopupView {
            popupView.superViewController = self
            popupView.completionBlock = completionBlock
            popupView.viewModel = itinerariesViewModel
            popupView.locationPopupDismissButton.addTarget(self, action: #selector(UIViewController.dismissPopup), for: .touchUpInside)
            Globals.rootViewController.view.addSubview(popupView)
            popupView.frame = UIScreen.main.bounds
            popupView.alpha = 0.0
            popupView.fadeIn(duration: 0.2, completion: nil)
            popupView.playBounceAnimation([0.6 ,1.1, 1], duration: 0.4)
            popupView.locationTextField.becomeFirstResponder()
        }
    }

    func showSavedCollectionPopup(_ itineraryDetailViewModel: ItineraryDetailViewModel, completionBlock: SaveItineraryPopupView.CompletionBlock? = nil) {
        guard Globals.currentUser != nil else { return }
        let nib = UINib.init(nibName: "SaveItineraryPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? SaveItineraryPopupView {
            popupView.superViewController = self
            popupView.completionBlock = completionBlock
            popupView.viewModel = SavedCollectionViewModel(model: itineraryDetailViewModel)
            configureCollectionPopup(popupView)
        }
    }
    
    func showDeletedCollectionPopup(_ savedCollectionDetailViewModel: SavedCollectionDetailViewModel, collectionDidDeleteBlock: SaveItineraryPopupView.CompletionBlock? = nil) {
        guard Globals.currentUser != nil else { return }
        let nib = UINib.init(nibName: "SaveItineraryPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? SaveItineraryPopupView {
            popupView.superViewController = self
            popupView.completionBlock = collectionDidDeleteBlock
            popupView.viewModel = SavedCollectionViewModel(collectionModel: savedCollectionDetailViewModel, mode: .delete)
            configureCollectionPopup(popupView)
        }
    }
    
    func showRenameCollectionPopup(_ savedCollectionDetailViewModel: SavedCollectionDetailViewModel) {
        guard Globals.currentUser != nil else { return }
        let nib = UINib.init(nibName: "SaveItineraryPopupView", bundle: nil)
        if let popupView = nib.instantiate(withOwner: nil, options: nil).first as? SaveItineraryPopupView {
            popupView.viewModel = SavedCollectionViewModel(collectionModel: savedCollectionDetailViewModel, mode: .rename)
            popupView.superViewController = self
            configureCollectionPopup(popupView)
        }
    }
    
    func configureCollectionPopup(_ saveItineraryPopupView: SaveItineraryPopupView) {
        guard Globals.currentUser != nil else { return }
        
        saveItineraryPopupView.dismissButton.addTarget(self, action: #selector(UIViewController.dismissPopup), for: .touchUpInside)
        Globals.rootViewController.view.addSubview(saveItineraryPopupView)
        saveItineraryPopupView.frame = UIScreen.main.bounds
        saveItineraryPopupView.alpha = 0.0
        saveItineraryPopupView.fadeIn(duration: 0.2, completion: nil)
        saveItineraryPopupView.playBounceAnimation([0.6 ,1.1, 1], duration: 0.4)
    }
    
    func fadeOutPopup() {
        for view in Globals.rootViewController.view.subviews {
            if view is SaveItineraryPopupView ||
                view is LocationPopupView ||
                view is SortPopupView ||
                view is NoPermissionView {
                view.fadeOut(duration: 0.2) { (_) in
                    view.removeFromSuperview()
                }
                view.fadeOut(duration: 0.2, completion: nil)
                view.endEditing(true)
            }
        }
    }
    
    @objc func dismissPopup() {
        fadeOutPopup()
    }
    
    func showNoPermissionViewIfNeeded() -> Bool {
        if Globals.currentUser == nil {
            let nib = UINib.init(nibName: "NoPermissionView", bundle: nil)
            if let view = nib.instantiate(withOwner: nil, options: nil).first as? NoPermissionView {
                view.superViewController = self
                view.dismissButton.addTarget(self, action: #selector(UIViewController.dismissPopup), for: .touchUpInside)
                view.frame = UIScreen.main.bounds
                Globals.rootViewController.view.addSubview(view)
                view.alpha = 0.0
                view.fadeIn(duration: 0.2, completion: nil)
                view.playBounceAnimation([0.6 ,1.1, 1], duration: 0.4)
            }
            return true
        }
        fadeOutPopup()
        return false
    }
    
    func showSplashScreen() {
        let view = UIView()
        view.tag = 9999
        let bgImageView = UIImageView(image: #imageLiteral(resourceName: "SplashScreenBg"))
        bgImageView.contentMode = .scaleAspectFill
        let logoImageView = UIImageView(image: #imageLiteral(resourceName: "BigLogo"))
        logoImageView.contentMode = .center
        view.addSubview(bgImageView)
        view.addSubview(logoImageView)
        view.frame = UIScreen.main.bounds
        bgImageView.frame = UIScreen.main.bounds
        logoImageView.frame = UIScreen.main.bounds
        Globals.rootViewController.view.addSubview(view)
    }
    
    func dismissSplashScreen() {
        let view = Globals.rootViewController.view.viewWithTag(9999)
        view?.fadeOut(duration: 0.3, completion: { (result) in
            view?.removeFromSuperview()
        })
    }
    
}


