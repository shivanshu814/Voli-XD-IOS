//
//  FacebookLoginable.swift
//  PineApple
//
//  Created by Tao Man Kit on 24/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import FirebaseAuth
import AuthenticationServices

protocol AppleLoginable where Self: UIViewController {
    var viewModel: ProfileViewModel! { get set }
}

extension AppleLoginable {
    @available(iOS 13.0, *)
    func handleLoginButtonDidClicked(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = viewModel.currentNonce else {
                    showAlert(title: "Error", message: "Invalid state: A login callback was received, but no login request was sent.")
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    showAlert(title: "Error", message: "Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    showAlert(title: "Error", message: "Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                // Initialize a Firebase credential.
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                // Sign in with Firebase.
                showLoading()
                Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                    guard let strongSelf = self else { return }
                    if error == nil, let firUser = Auth.auth().currentUser, let email = firUser.email, !email.isEmpty {
                        User.currentUser({[weak self] (result, error) in
                            guard let strongSelf = self else { return }
                            
                            if Globals.currentUser == nil {
                                ProfileViewModel.createUser(with: email, loginType: "apple", completionHandler: { (result, error) in
                                    strongSelf.stopLoading()
                                    if let error = error {
                                        strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                                    } else {
                                        strongSelf.performSegue(withIdentifier: "WelcomeSegue", sender: nil)
                                    }
                                })
                            } else {
                                strongSelf.stopLoading()
                                strongSelf.performSegue(withIdentifier: "ProfileSegue", sender: nil)
                            }
                        })
                        
                    } else {
                        strongSelf.stopLoading()
                        strongSelf.showAlert(title: "Error", message: error?.localizedDescription ?? "Unknown error")
                    }
                    
                }
            }
    }
    
}
