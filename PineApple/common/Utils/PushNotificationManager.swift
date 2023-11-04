//
//  PushNotificationManager.swift
//  PineApple
//
//  Created by Tao Man Kit on 26/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications
import SwiftMessageBar

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationManager()
    
    func registerForPushNotifications() {
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        // For iOS 10 data message (sent via FCM)
        Messaging.messaging().delegate = self
        
        
        UIApplication.shared.registerForRemoteNotifications()
        updateFirestorePushTokenIfNeeded()
        
        
    }
    
    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken, Globals.currentUser != nil {
            if Globals.currentUser!.token != token {
                Globals.currentUser!.token = token
                User.updateToken(Globals.currentUser!) { (result, error) in
                    print("update token: " + (result ? "success" : "fail"))
                    // TODO: update token in following user
                    
                }
            }
        }
    }
    
    func removeFirestorePushToken() {
        if Globals.currentUser != nil {
            Globals.currentUser!.token = ""
            User.updateToken(Globals.currentUser!) { (result, error) in
                print("update token: " + (result ? "success" : "fail"))
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
        
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        updateFirestorePushTokenIfNeeded()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
        PushNotificationManager.shared.handleNotification(userInfo: response.notification.request.content.userInfo, fromNotificationCenter: true)
        
    }
    
    func sendPushNotification(to token: String, title: String, body: String, data: [String: Any] = [String: Any]()) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body],
                                           "data" : data
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAb-NoDUs:APA91bEII3sgHJxs1i1GsuzqUOoC6bdiMJYPsk7vZ5eZh35K-7vGT5YtgiTGBub60BRrFYAtpF2cLMM7C1qoRYG3S__gjxqwVSF2I6MnEu-je7UwQIN5sqNaKKi13ur1zdYQVeRVNszZ", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    func sendGroupPushNotification(userId: String, title: String, body: String) {
        getGroupPushNotificationKey(userId, completionHandler: { (token, error) in
            if !token.isEmpty {
                let urlString = "https://fcm.googleapis.com/fcm/send"
                let url = NSURL(string: urlString)!
                let paramString: [String : Any] = ["to" : token,
                                                   "notification" : ["title" : title, "body" : body]
                ]
                let request = NSMutableURLRequest(url: url as URL)
                request.httpMethod = "POST"
                request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("key=AAAAb-NoDUs:APA91bEII3sgHJxs1i1GsuzqUOoC6bdiMJYPsk7vZ5eZh35K-7vGT5YtgiTGBub60BRrFYAtpF2cLMM7C1qoRYG3S__gjxqwVSF2I6MnEu-je7UwQIN5sqNaKKi13ur1zdYQVeRVNszZ", forHTTPHeaderField: "Authorization")
                let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
                    do {
                        if let jsonData = data {
                            if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                                NSLog("Received data:\n\(jsonDataDict))")
                            }
                        }
                    } catch let err as NSError {
                        print(err.debugDescription)
                    }
                }
                task.resume()
            }
        })
        
    }
    
    func addToGroupNotification(_ userId: String, completionHandler:  RequestDidCompleteBlock? = nil) {
        getGroupPushNotificationKey(userId, completionHandler: {[weak self] (token, error) in
            if token.isEmpty {
                self?.createGroupPushNotification(userId, ids: [Globals.currentUser!.token])
            } else {
                self?.updateGroupPushNotification("add", userId: userId, groupToken: token, ids: [Globals.currentUser!.token])
            }
        })
    }
    
    func removeFromGroupNotification(_ userId: String, completionHandler:  RequestDidCompleteBlock? = nil) {
        getGroupPushNotificationKey(userId, completionHandler: {[weak self] (token, error) in
            if !token.isEmpty {
                self?.updateGroupPushNotification("remove", userId: userId, groupToken: token, ids: [Globals.currentUser!.token])
                completionHandler?(true, error)
            } else {
                completionHandler?(false, error)
            }
            
        })
    }
    
    func getGroupPushNotificationKey(_ userId: String, completionHandler: ((String, Error?) -> Void)? = nil) {
        let urlString = "https://fcm.googleapis.com/fcm/notification?notification_key_name=\(userId)"
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("480556617035", forHTTPHeaderField: "project_id")
        request.setValue("key=AAAAb-NoDUs:APA91bEII3sgHJxs1i1GsuzqUOoC6bdiMJYPsk7vZ5eZh35K-7vGT5YtgiTGBub60BRrFYAtpF2cLMM7C1qoRYG3S__gjxqwVSF2I6MnEu-je7UwQIN5sqNaKKi13ur1zdYQVeRVNszZ", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
//                        if let groupToken = jsonDataDict["notification_key"] as? String {
//                            Globals.currentUser!.groupToken = groupToken
//                            User.updateGroupToken(Globals.currentUser!) { (result, error) in
//                                if let error = error {
//                                    completionHandler?("", error)
//                                } else {
//                                    completionHandler?(groupToken, nil)
//                                }
//                            }
//                        }
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
                completionHandler?("", err)
            }
        }
        task.resume()
    }
    
    
    func createGroupPushNotification(_ userId: String, ids: [String], completionHandler: ((String, Error?) -> Void)? = nil) {
        let urlString = "https://fcm.googleapis.com/fcm/notification"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["operation" : "create",
                                           "notification_key_name" : userId,
                                           "registration_ids" : ids
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("480556617035", forHTTPHeaderField: "project_id")
        request.setValue("key=AAAAb-NoDUs:APA91bEII3sgHJxs1i1GsuzqUOoC6bdiMJYPsk7vZ5eZh35K-7vGT5YtgiTGBub60BRrFYAtpF2cLMM7C1qoRYG3S__gjxqwVSF2I6MnEu-je7UwQIN5sqNaKKi13ur1zdYQVeRVNszZ", forHTTPHeaderField: "Authorization")
        
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  {[weak self] (data, response, error) in
            do {
                guard let strongSelf = self else { return }
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                        if let error = jsonDataDict["error"] as? String {
                            if error == "notification_key already exists" {
                                strongSelf.getGroupPushNotificationKey(userId)
                            }
                        } else {
                            if let groupToken = jsonDataDict["notification_key"] as? String {
                                completionHandler?(groupToken, nil)                                
                            } else {
                                completionHandler?("", error)
                            }
                            
                        }
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
                completionHandler?("", err)
            }
        }
        task.resume()
    }
    
    func updateGroupPushNotification(_ action: String, userId: String, groupToken: String, ids: [String], completionHandler: RequestDidCompleteBlock? = nil) {
        let urlString = "https://fcm.googleapis.com/fcm/notification"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["operation" : action,
                                           "notification_key_name" : userId,
                                           "notification_key": groupToken,
                                           "registration_ids" : ids
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("480556617035", forHTTPHeaderField: "project_id")
        request.setValue("key=AAAAb-NoDUs:APA91bEII3sgHJxs1i1GsuzqUOoC6bdiMJYPsk7vZ5eZh35K-7vGT5YtgiTGBub60BRrFYAtpF2cLMM7C1qoRYG3S__gjxqwVSF2I6MnEu-je7UwQIN5sqNaKKi13ur1zdYQVeRVNszZ", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                        completionHandler?(true, nil)
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
                completionHandler?(false, err)
            }
        }
        task.resume()
    }
    
    func handleNotification(userInfo: [AnyHashable: Any], fromNotificationCenter: Bool = false) {
        print(userInfo)
        if let aps = userInfo["aps"] as? [AnyHashable: Any], let alert = aps["alert"] as? [AnyHashable: Any], let title = alert["title"] as? String, let body = alert["body"] as? String {
            let showChannel = {
                if let channelId = userInfo["channel"] as? String {
                    Globals.rootViewController.dismiss(animated: true, completion: nil)
                    Globals.rootViewController.selectedIndex = 4
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                        NotificationCenter.default.post(name: .messageDidReceived, object: nil, userInfo: ["channel": channelId])
                    }                    
                }
            }
            
            if fromNotificationCenter {
                showChannel()
            } else {
                SwiftMessageBar.showMessage(withTitle: title, message: body, type: .info, duration: 5, dismiss: true) {
                    showChannel()
                }
            }
            
        }
    }
}
