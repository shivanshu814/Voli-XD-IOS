//
//  Globals.swift
//  PineApple
//
//  Created by Tao Man Kit on 26/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import FirebaseAuth
import MessageUI
import Firebase
import CoreLocation

// MARK: - Global Veriable

typealias RequestDidCompleteBlock = (Bool, Error?) -> Void
typealias CountRequestDidCompleteBlock = (Int, Error?) -> Void
var shareCollectionInfo: [String: String]?
var globalNumShards = 10

// MARK: - Helper

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

func getProfileImagePath(isThumbnail value: Bool = false) -> String {
    return getImagePath(0, isThumbnail: value, directory: "Profile")
}

func saveImageForUpload(_ initialImage: UIImage, suffix: Int = 0, isProfile: Bool = true) -> (path: String, thumbnail: String)? {
    let path = isProfile ? getProfileImagePath() : getImagePath(suffix)
    let thumbnailPath = isProfile ? getProfileImagePath(isThumbnail: true) : getImagePath(suffix, isThumbnail: true)
    do {
        let image = initialImage.resizeToNormal()
        let thumbnail = isProfile ? initialImage.resizeToVerySmall() : initialImage.resizeToSmall()
        try image.saveToPath(path)
        try thumbnail.saveToPath(thumbnailPath)
        return (path, thumbnailPath)
    } catch {
        print(error)
        return nil
    }
}

func getImagePath(_ suffix: Int, isThumbnail: Bool = false, directory: String = "Attachments") -> String {
    return "\(SEARCH_PATH)/\(directory)/Image\(suffix)\(isThumbnail ? "_small" : "").jpg"
}

class Globals: NSObject {
    
    static let shared = Globals()
    static var rootViewController: TabBarViewController!
    static var currentUser: User?
    static var isLogined = false
    static var isLocationUpdated = false
    
    static var topViewController: UIViewController {
        if Globals.rootViewController.presentedViewController != nil {
            return Globals.rootViewController.presentedViewController!
        } else {
            let index = Globals.rootViewController.selectedIndex
            if let vcs = Globals.rootViewController.viewControllers, let navCtrl = vcs[index] as? UINavigationController, let vc = navCtrl.viewControllers.last {
                return vc
            }
            
            return Globals.rootViewController
        }
    }
    
    static var cityCenter = [String: CLLocation]()
    
    static func generateDynamicLink(type: DynamicLinkType, id: String, name: String? = nil, completionHandler: @escaping (URL?) -> Void) {
        guard let link = type.url(id: id, name: name) else { return }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
        linkBuilder?.iOSParameters?.appStoreID = appStoreID
        linkBuilder?.navigationInfoParameters = DynamicLinkNavigationInfoParameters()
        linkBuilder?.navigationInfoParameters?.isForcedRedirectEnabled = false
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "Voli XD is an itinerary sharing app, allows users to create trip plan and share alternative and unique travel activities, ask for help when they need when they are away from home."
        linkBuilder?.socialMetaTagParameters?.descriptionText = "There are something you may be interested. Pleaes check it out!"
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: appIconURL)
        
        linkBuilder?.shorten() { url, warnings, error in
            if error == nil {
                print(url?.absoluteString ?? "")
                completionHandler(url)
                
            }
        }
    }
    
    static func handleShareCollection() {
        if shareCollectionInfo != nil {
            Globals.topViewController.showSavedCollectionPage()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {
                NotificationCenter.default.post(name: .sharedCollectionDidReceived, object: nil, userInfo: shareCollectionInfo)
                shareCollectionInfo = nil
            })
        }
    }
    
    static func configureProfileDirectory() {
        let path = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true).first!)/Profile"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    static func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if length == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
}

// MARK - MFMailComposeViewControllerDelegate

extension Globals: MFMailComposeViewControllerDelegate{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
