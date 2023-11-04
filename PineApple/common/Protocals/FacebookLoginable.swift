//
//  FacebookLoginable.swift
//  PineApple
//
//  Created by Tao Man Kit on 24/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import FirebaseAuth

protocol FacebookLoginable where Self: UIViewController {
    var viewModel: ProfileViewModel! { get set }
}

extension FacebookLoginable {
    func handleLoginButtonDidClicked(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let result = result, result.isCancelled { return }
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        showLoading()
        let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
        Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
            guard let strongSelf = self else { return }
            if error == nil, let firUser = Auth.auth().currentUser, let email = firUser.email, !email.isEmpty {
                User.currentUser({[weak self] (result, error) in
                    guard let strongSelf = self else { return }
                    
                    if Globals.currentUser == nil {
                        ProfileViewModel.createUser(with: email, loginType: "facebook", completionHandler: { (result, error) in
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
