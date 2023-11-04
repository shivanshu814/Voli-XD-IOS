//
//  SignInViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 13/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import FBSDKLoginKit
import GoogleSignIn
import NVActivityIndicatorView
import AuthenticationServices

class SignInViewController: BaseViewController, ViewModelBased, KeyboardOverlayAvoidable, FacebookLoginable, AppleLoginable {
    
    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case createSegue = "CreateProfileSegue"
        case profileSegue = "ProfileSegue"
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginStackView: UIStackView!
    
    
    var authorizationButton: UIControl!
    var fbLoginButton: FBLoginButton!
    var viewModel: ProfileViewModel!    
    var keyboardHeight: CGFloat = 0
    var keyboardDidShowBlock: (() -> Void)?
    private let footerHeight: CGFloat = 136
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSignInAppleButton()
        configureNavigationbar()
        configureTableView()
        configureLoginButtons()
        bindViewModel(ProfileViewModel())
        bindAction()
        addKeyboardNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance().presentingViewController = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - RX
extension SignInViewController {
    
    func bindViewModel(_ viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        
        viewModel.loginRows
            .bind(to: tableView.rx.items) { tableView, index, element in
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! TextFieldTableViewCell
                cell.bindViewModel(element)
                cell.textField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
                if index == 0 {
                    cell.textField.keyboardType = .emailAddress
                } else if index == 1 {
                    cell.textField.isSecureTextEntry = true
                }
                return cell
            }.disposed(by: disposeBag)
        
        viewModel.loginRows
            .asObservable()
            .bind {[weak self] (rows) in
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        
        appleButton.rx.tap
        .bind{ [weak self] in
                if #available(iOS 13, *) {
                    guard let strongSelf = self else { return }
                    let authorizationController = strongSelf.viewModel.startSignInWithAppleFlow()
                    authorizationController.delegate = strongSelf
                    authorizationController.presentationContextProvider = strongSelf as? ASAuthorizationControllerPresentationContextProviding
                    authorizationController.performRequests()
                }
            }.disposed(by: disposeBag)
        
        
        forgotPasswordButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.forgotPassword({[weak self] (isSuccess, error) in
                    strongSelf.stopLoading()
                    if error != nil {
                        self?.showAlert(title: "Error", message: error!.localizedDescription)
                    } else {
                        self?.showAlert(title: "", message: "A password reset email is sent.")
                    }
                })
                strongSelf.tableView.update()
            }.disposed(by: disposeBag)
        
        signInButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.signIn({[weak self] (isSuccess, error) in
                    
                    strongSelf.stopLoading()
                    if isSuccess {
                        self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                        self?.performSegue(withIdentifier: SegueIdentifier.profileSegue.rawValue, sender: nil)
                    } else {
                        if error != nil {
                            self?.showAlert(title: "Error", message: error!.localizedDescription)
                        }
                    }
                })
                strongSelf.tableView.update()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
                
            }.disposed(by: disposeBag)
        
        fbButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.fbLoginButton.sendActions(for: .touchUpInside)
            }.disposed(by: disposeBag)
        
        googleButton.rx.tap
            .bind{
                GIDSignIn.sharedInstance()?.signIn()
            }.disposed(by: disposeBag)
        
    }
    
}

// MARK: - Private
extension SignInViewController {
    
    private func setUpSignInAppleButton() {
        if #available(iOS 13.0, *) {
            loginStackView.spacing = 8
            authorizationButton = ASAuthorizationAppleIDButton(type: .continue, style: .black)
            authorizationButton.addTarget(viewModel, action: #selector(ProfileViewModel.startSignInWithAppleFlow), for: .touchUpInside)
            authorizationButton.isHidden = true
            view.addSubview(authorizationButton)
        } else {
            appleButton.isHidden = true
        }
    }
    
    private func configureNavigationbar() {
        title = "Sign in"
        if navigationController?.viewControllers.count == 1 {
            addCloseButton()
        } else {
            addBackButton()
        }
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: TextFieldTableViewCell.self)
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

// MARK: - LoginButtonDelegate
extension SignInViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        handleLoginButtonDidClicked(loginButton, didCompleteWith: result, error: error)
    }
}


@available(iOS 13.0, *)
extension SignInViewController: ASAuthorizationControllerDelegate {

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleLoginButtonDidClicked(controller: controller, didCompleteWithAuthorization: authorization)
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
        print("Sign in with Apple errored: \(error)")
  }

}
