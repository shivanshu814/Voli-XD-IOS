//
//  UserProfileLandingViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 12/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import NVActivityIndicatorView
import AuthenticationServices

class UserProfileLandingViewController: UIViewController, ViewModelBased, FacebookLoginable {
    

    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case welcomeSegue = "WelcomeSegue"
        case createSegue = "CreateProfileSegue"
        case signInSegue = "SignInSegue"
        case profileSegue = "ProfileSegue"
    }
    
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var loginStackView: UIStackView!
    var authorizationButton: UIControl!
    var fbLoginButton: FBLoginButton!
    private let disposeBag = DisposeBag()
    var viewModel: ProfileViewModel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationController.shared.locationForCreatingAcc = true
        LocationController.shared.startUpdatingLocation()
        ProfileViewModel.configureProfileDirectory()
        setUpSignInAppleButton()
        configureNavigationbar()
        configureLoginButtons()
        bindViewModel(ProfileViewModel())
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance().presentingViewController = self        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - RX
extension UserProfileLandingViewController {
    
    func bindViewModel(_ viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    func bindAction() {
        
        emailButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                strongSelf.performSegue(withIdentifier: SegueIdentifier.createSegue.rawValue, sender: nil)
            }.disposed(by: disposeBag)
        
        fbButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                LocationController.shared.stopUpdatingLocation()
                if LocationController.shared.location != nil {
                    strongSelf.fbLoginButton.sendActions(for: .touchUpInside)
                } else {
                    strongSelf.showLocationPermissionAlert(true)
                }
            }.disposed(by: disposeBag)
        
        googleButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if LocationController.shared.location != nil {
                    GIDSignIn.sharedInstance()?.signIn()
                } else {
                    strongSelf.showLocationPermissionAlert(true)
                }
                
            }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension UserProfileLandingViewController {
    
    private func setUpSignInAppleButton() {
        if #available(iOS 13.0, *) {
            authorizationButton = ASAuthorizationAppleIDButton(type: .continue, style: .black)
            authorizationButton.addTarget(viewModel, action: #selector(ProfileViewModel.startSignInWithAppleFlow), for: .touchUpInside)
            authorizationButton.isHidden = true
            view.addSubview(authorizationButton)
        }
    }
    
    private func configureNavigationbar() {
        title = "Create profile"
        addCloseButton()
    }
    
    private func configureLoginButtons() {        
        if fbLoginButton == nil {
            fbLoginButton = FBLoginButton(frame: CGRect(x: 0, y: 0, width: view.frame.width-100, height: 48))
            fbLoginButton.translatesAutoresizingMaskIntoConstraints = false
            fbLoginButton.permissions = ["email", "public_profile"]
            fbLoginButton.delegate = self
            view.addSubview(fbLoginButton)

        }
    }
    
}

// MARK: - LoginButtonDelegate
extension UserProfileLandingViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) { }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        handleLoginButtonDidClicked(loginButton, didCompleteWith: result, error: error)
    }
}

