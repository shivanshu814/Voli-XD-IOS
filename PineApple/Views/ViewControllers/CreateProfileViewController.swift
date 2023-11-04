//
//  CreateProfileViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 11/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices

class CreateProfileViewController: BaseViewController, ViewModelBased, KeyboardOverlayAvoidable, FacebookLoginable, AppleLoginable {
    
    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case signInSegue = "SignInSegue"
        case welcomeSegue = "WelcomeSegue"
        case locationSegue = "LocationSegue"
        case profileSegue = "ProfileSegue"
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var privateButton: UIButton!
    @IBOutlet weak var privateOverlayButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var loginStackView: UIStackView!
    
    
    var authorizationButton: UIControl!
    var fbLoginButton: FBLoginButton!
    var viewModel: ProfileViewModel!    
    var keyboardHeight: CGFloat = 0
    var keyboardDidShowBlock: (() -> Void)?
    let footerHeight: CGFloat = 119
    

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationController.shared.locationForCreatingAcc = true
        LocationController.shared.startUpdatingLocation()
        setUpSignInAppleButton()
        configureNavigationbar()
        configureTableView()
        configureLoginButtons()
        bindViewModel(ProfileViewModel())
        bindAction()
        addKeyboardNotification()
        
        LocationController.shared.startUpdatingLocation()
        NotificationCenter.default.addObserver(forName: .locationPermissionDidChanged, object: nil, queue: nil) {[weak self] (_) in
            self?.viewModel.getCountry()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance().presentingViewController = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
extension CreateProfileViewController {
    
    func bindViewModel(_ viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        
        viewModel.isPrivate
            .asDriver()
            .drive(privateButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        viewModel.createRows
            .bind(to: tableView.rx.items) { tableView, index, element in
                if element is ColumnTextFieldViewModel {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ColumnTextFieldTableViewCell", for: IndexPath(row: index, section: 0)) as! ColumnTextFieldTableViewCell
                    cell.bindViewModel(viewModel.createRows.value[index] as! ColumnTextFieldViewModel)
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
                    cell.bindViewModel(viewModel.createRows.value[index])
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
                    }  else if index == 2 {
                        cell.textField.isSecureTextEntry = true
                    }
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.createRows
            .asObservable()
            .bind {[weak self] (rows) in
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
        }
        .disposed(by: disposeBag)
        
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
        
        createButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.create({ (success, error) in
                    strongSelf.stopLoading()
                    if success {
                        strongSelf.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                        strongSelf.performSegue(withIdentifier: SegueIdentifier.welcomeSegue.rawValue, sender: nil)
                    } else {
                        if error != nil {
                            strongSelf.showAlert(title: "Error", message: error!.localizedDescription)
                        }
                    }
                })
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
extension CreateProfileViewController {
    
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
        title = "Join Voli XD"
        if navigationController?.viewControllers.count == 1 {
            addCloseButton()
        } else {
            addBackButton()
        }
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: TextFieldTableViewCell.self)
        tableView.register(nibWithCellClass: ColumnTextFieldTableViewCell.self)
       
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
extension CreateProfileViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) { }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        handleLoginButtonDidClicked(loginButton, didCompleteWith: result, error: error)    
    }
}

@available(iOS 13.0, *)
extension CreateProfileViewController: ASAuthorizationControllerDelegate {

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleLoginButtonDidClicked(controller: controller, didCompleteWithAuthorization: authorization)
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
        print("Sign in with Apple errored: \(error)")
  }

}
