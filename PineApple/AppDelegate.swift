//
//  AppDelegate.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GoogleMapsDirections
import Firebase
import GoogleSignIn
import NVActivityIndicatorView
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let GMS_API_KEY = "AIzaSyA-1vEzh_5qgOIcGDKv-eWEpGG6ZdnZ5TY"
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {        
        UserDefaults.standard.set(["en_US"], forKey: "AppleLanguages")        
        FirebaseApp.configure()
        Styles.setup()
        GMSServices.provideAPIKey(GMS_API_KEY)
        GMSPlacesClient.provideAPIKey(GMS_API_KEY)
        GoogleMapsDirections.provide(apiKey: "AIzaSyBlZIfhPkKXCnggpsyytAgCS-cd_1UT-y8")
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        Globals.topViewController.dismissKeyboard()
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        LocationController.shared.startUpdatingLocation()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
        -> Bool {
            if url.absoluteString.contains("volixd") {
                return application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: "")
            }
            return GIDSignIn.sharedInstance().handle(url)
    }
    

}

// MARK - Notification
extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        PushNotificationManager.shared.handleNotification(userInfo: userInfo)
    }

}

// MARK - Dynamic link
extension AppDelegate {
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) {[weak self] (dynamicLink, error) in
        if let url = dynamicLink?.url {
            self?.handleDynamicLink(url)
        }
        
      }

      return handled
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        if let url = dynamicLink.url {
            handleDynamicLink(url)
        }
        return true
      }
      return false
    }
    
    func handleDynamicLink(_ url: URL) {
        print(url)
        if url.absoluteString.contains("itinerary") {
            let components = url.absoluteString.components(separatedBy: "/itinerary/")
            if components.count > 1, let id = components[1].components(separatedBy: "/").first {
                Globals.topViewController.showItineraryDetailPage(ItineraryDetailViewModel(id: id), isPresentModelView: false)
            }
        } else if url.absoluteString.contains("profile") {
            let components = url.absoluteString.components(separatedBy: "/profile/")
            if components.count > 1, let id = components[1].components(separatedBy: "/").first {
                Globals.topViewController.showUserProfilePage(ProfileDetailViewModel(id: id), isPresentModelView: false)
            }
        } else if url.absoluteString.contains("collection") {
            let components = url.absoluteString.components(separatedBy: "/collection/")
            if components.count > 1 {
                let info = components[1].components(separatedBy: "/")
                if info.count > 2 {
                    let id = info[0]
                    let uid = info[1]
                    let name = info[2].urlDecoded                    
                    shareCollectionInfo = ["id": id, "name": name, "uid": uid]
                    if Globals.currentUser != nil {
                        Globals.handleShareCollection()
                    } 
                }
                
            }
        }
    }
}

// MARK - GIDSignInDelegate
extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let authentication = user.authentication else { return }
        
        GIDSignIn.sharedInstance()?.presentingViewController.showLoading()
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)

        let email = user.profile.email!
        User.findByEmail(email) { (user, error) in
            if let error = error {
                Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                
                let isRegistered = user != nil
                let isRegisteredByOthers = isRegistered && user!.loginType != "google"
                
                if isRegisteredByOthers {
                    GIDSignIn.sharedInstance()?.presentingViewController.stopLoading()
                    Globals.topViewController.showAlert(title: "Error", message: "An account already exits with the same email address but different sign-in credentials. Sign in using a provider associated with this email address.")
                } else {
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                        if let error = error {
                            GIDSignIn.sharedInstance()?.presentingViewController.stopLoading()
                            Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                            return
                        }
                        
                        if isRegistered {
                            User.currentUser({ (result, error) in
                                GIDSignIn.sharedInstance()?.presentingViewController.stopLoading()
                                if let error = error {
                                    Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                                } else {
                                    let viewController = GIDSignIn.sharedInstance()?.presentingViewController
                                    viewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                                    viewController?.performSegue(withIdentifier: "ProfileSegue", sender: nil)
                                }
                            })
                        } else {
                            ProfileViewModel.createUser(with: email, loginType: "google", completionHandler: { (result, error) in
                                GIDSignIn.sharedInstance()?.presentingViewController.stopLoading()
                                if let error = error {
                                    Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                                } else {
                                    let viewController = GIDSignIn.sharedInstance()?.presentingViewController
                                    viewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                                    viewController?.performSegue(withIdentifier: "WelcomeSegue", sender: nil)
                                }
                            })
                        }
                        
                    }
                }
                
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
    }
}

