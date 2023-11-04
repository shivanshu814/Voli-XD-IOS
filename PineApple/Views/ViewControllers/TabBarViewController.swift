//
//  TabBarViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import SwifterSwift
import FirebaseAuth

class TabBarViewController: UITabBarController {

    // MARK: - Properties
    var lastIndex = 0
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        delegate = self
        tabBar.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.shadowColor = UIColor(hex: 0xA5A5A5)
        tabBar.shadowRadius = 13
        tabBar.shadowOpacity = 0.2
        tabBar.layer.masksToBounds = false
        var image = UIImage(named: "Rectangle_49")
        var hasBottomSafeArea = false
        if let keyWindow = UIApplication.shared.windows.first, keyWindow.safeAreaInsets.bottom > 0 {
            image = UIImage(named: "Rectangle")
            hasBottomSafeArea = true
        }
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: .normal)
        
        if #available(iOS 13.0, *) {
            let appearance = tabBar.standardAppearance
            appearance.shadowImage = nil
            appearance.shadowColor = nil
            appearance.configureWithTransparentBackground()
            appearance.backgroundImage = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), resizingMode: .stretch)
            let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.clear]
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = titleTextAttributes
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = titleTextAttributes
            appearance.stackedLayoutAppearance.normal.iconColor = Styles.black
            appearance.stackedLayoutAppearance.selected.iconColor = Styles.p6A0DFF

            tabBar.standardAppearance = appearance;
        } else {
            tabBar.backgroundImage = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), resizingMode: .stretch)
            tabBar.shadowImage = UIImage()
            tabBar.backgroundColor = UIColor.clear
            tabBar.isTranslucent = true
            tabBar.tintColor = Styles.p6A0DFF
            tabBar.unselectedItemTintColor = UIColor.black
        }
        
        let array = customizableViewControllers
        for controller in array! {
            let y: CGFloat = hasBottomSafeArea ? 10.0 : 5.0
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: y, left: 0, bottom: y * -1, right: 0)
            controller.tabBarItem.title = nil
            
        }
        
        tabBar.layer.cornerRadius = 13
        tabBar.contentMode = .top
        tabBar.clipsToBounds = false
                
        Globals.rootViewController = self
           
    }
    
    func setSelectIndex(from: Int, to: Int) {
        selectedIndex = to
        lastIndex = to
    }
    
    func selectLastIndex() {
        selectedIndex = lastIndex
    }
    
}

// MARK: - UITabBarControllerDelegate
extension TabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let user = Auth.auth().currentUser, !user.isAnonymous {
            if Globals.currentUser == nil {
                // wait for session validation finish
                return false
            }
        }
        
        lastIndex = selectedIndex
        if let navCtrl = viewController as? UINavigationController, let firstController = navCtrl.viewControllers.first, firstController is CreateItineraryViewController, navCtrl.viewControllers.count > 1  {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateItineraryViewController") as! CreateItineraryViewController
            navCtrl.viewControllers = [vc]
        }
                
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem){
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            let orderedTabBarItemViews: [UIView] = {
                let interactionViews = tabBar.subviews.filter({ $0 is UIControl })
                return interactionViews.sorted(by: { $0.frame.minX < $1.frame.minX })
            }()
            
            guard
                let index = tabBar.items?.index(of: item),
                let subview = orderedTabBarItemViews[index].subviews.first
                else { return }
                        
            subview.playBounceAnimation()
        }
        
    }
}
