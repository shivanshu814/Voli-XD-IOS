//
//  UIViewController+Navigation.swift
//  PineApple
//
//  Created by Tao Man Kit on 26/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import Hero

extension UIViewController {
    
    func showChatRoom(_ channel: ATCChatChannel) {
        if let currentUser = Globals.currentUser {
            let vc = ATCChatThreadViewController(user: currentUser.atcUser, channel: channel, uiConfig: uiConfig)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
        
    func showItineraryDetailPage(_ vm: ItineraryDetailViewModel, isPresentModelView: Bool = false, isJustCreated: Bool = false) {
        let itineraryDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ItineraryDetailViewController") as! ItineraryDetailViewController
        if !vm.itinerary.id.isEmpty && vm.itinerary.title.isEmpty  {
            itineraryDetailViewController.viewModel = vm            
        } else {
            itineraryDetailViewController.viewModel = ItineraryDetailViewModel(itinerary: vm.itinerary)
        }
        itineraryDetailViewController.isJustCreated = isJustCreated
        if isPresentModelView {
            let navCtrl = UINavigationController(rootViewController: itineraryDetailViewController)
            navCtrl.modalPresentationStyle = .fullScreen
            present(navCtrl, animated: true, completion: nil)
        } else {
            itineraryDetailViewController.hidesBottomBarWhenPushed = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            navigationController?.pushViewController(itineraryDetailViewController, animated: true)
        }
    }
    
    func showSeeAllPage(_ vm: SuggestionsViewModel) {
        let seeAllViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SeeAllViewController") as! SeeAllViewController
        switch vm.type {
        case .tag, .image, .followingUser:
            seeAllViewController.viewModel = vm        
        default:
            seeAllViewController.viewModel = SuggestionsViewModel(itineraryViewModel: vm.itineraryViewModel, type: vm.type, subType: vm.similarSubType.value, isAll: true)
        }
        seeAllViewController.hidesBottomBarWhenPushed = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.pushViewController(seeAllViewController, animated: true)
    }
    
    func showCommentPage(_ vm: CommentViewModel) {
        let commentViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommentViewController") as! CommentViewController
        commentViewController.viewModel = vm
        let navCtrl = UINavigationController(rootViewController: commentViewController)
        navCtrl.modalPresentationStyle = .fullScreen
        present(navCtrl, animated: true, completion: nil)
        
    }
    
    func showUserProfilePage(_ vm: ProfileDetailViewModel, isPresentModelView: Bool = false) {
        let userProfileViewController = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        userProfileViewController.viewModel = vm
        if isPresentModelView {
            let navCtrl = UINavigationController(rootViewController: userProfileViewController)
            navCtrl.modalPresentationStyle = .fullScreen
            present(navCtrl, animated: true, completion: nil)
        } else {
            userProfileViewController.hidesBottomBarWhenPushed = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            navigationController?.pushViewController(userProfileViewController, animated: true)
        }
    }
    
    func showSavedCollectionPage() {
        Globals.rootViewController.setSelectIndex(from: Globals.rootViewController.lastIndex, to: 3)
    }
    
    @objc func showUserProfileLandingPage() {
        if let user = Auth.auth().currentUser, !user.isAnonymous {
            if Globals.currentUser != nil {
                let userProfileViewController = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
                userProfileViewController.hidesBottomBarWhenPushed = true
                navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                navigationController?.pushViewController(userProfileViewController, animated: true)
            } else {
                PushNotificationManager.shared.removeFirestorePushToken()
                ProfileDetailViewModel.logout()
                showUserProfileLandingPage()
            }
        } else {
            let createProfileViewController = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "CreateProfileViewController") as! CreateProfileViewController
            let navCtrl = UINavigationController(rootViewController: createProfileViewController)
            navCtrl.modalPresentationStyle = .fullScreen
            present(navCtrl, animated: true, completion: nil)
        }
        
    }
        
    @objc func showLoginPage() {
        let vc = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        let navCtrl = UINavigationController(rootViewController: vc)
        navCtrl.modalPresentationStyle = .fullScreen
        present(navCtrl, animated: true, completion: nil)
    }
        
    func showSettingPage() {
        let vc = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
        (navigationController ?? Globals.topViewController as? UINavigationController ?? Globals.topViewController.navigationController )?.interactivePopGestureRecognizer?.isEnabled = false
        (navigationController ?? Globals.topViewController as? UINavigationController ?? Globals.topViewController.navigationController )?.pushViewController(vc, animated: true)
    }
        
    func showCameraView(_ viewModel: CameraViewModel? = nil) {
        let cameraViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.viewModel = viewModel
        let navCtrl = UINavigationController(rootViewController: cameraViewController)
        navCtrl.isNavigationBarHidden = true
        navCtrl.modalPresentationStyle = .fullScreen
        present(navCtrl, animated: true, completion: nil)
    }
    
    func showUpdateProfilePage(with viewModel: ProfileViewModel) {
        let vc = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "UpdateProfileViewController") as! UpdateProfileViewController
        vc.viewModel = viewModel
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showShareToFollowingUserPage(_ url: URL, title: String, type: String) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.viewModel = FollowingViewModel(model: Globals.currentUser, mode: .share, shareLink: url, shareTitle: title, shareType: type)
        vc.addCloseButton()
        let navCtrl = UINavigationController(rootViewController: vc)
        navCtrl.modalPresentationStyle = .fullScreen
        present(navCtrl, animated: true, completion: nil)
    }
    
    func showFollowingUserPage(_ user: User) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.viewModel = FollowingViewModel(model: user, mode: .following)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showImagesSelectionPage(_ viewModel: ItineraryViewModel) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImagesSelectionViewController") as! ImagesSelectionViewController
        vc.viewModel = viewModel
        navigationController?.pushViewController(vc)
        
    }
    
    
    
}
