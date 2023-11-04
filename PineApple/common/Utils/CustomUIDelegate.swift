//
//  DKImagePickerController
//  NBCU
//
//  Created by Steven Tao on 22/10/2016.
//  Copyright © 2016 ROKO. All rights reserved.
//

import UIKit
import DKImagePickerController

open class CustomUIDelegate: DKImagePickerControllerBaseUIDelegate {
    
    
    open override func createDoneButtonIfNeeded() -> UIButton {
        if self.doneButton == nil {
            let button = UIButton(type: UIButton.ButtonType.custom)
            button.setTitleColor(UINavigationBar.appearance().tintColor ?? self.imagePickerController.navigationBar.tintColor, for: .normal)
            button.titleLabel?.font = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?[NSAttributedString.Key.font] as? UIFont
            self.updateDoneButtonTitle(button)
            self.doneButton = button
        }
        
        return self.doneButton!
    }
    
    open override func layoutForImagePickerController(_ imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type {
        return CustomAssetGroupGridLayout.self
    }
    
//    open override func createDoneButtonIfNeeded() -> UIButton {
//        let doneButton = super.createDoneButtonIfNeeded()
////        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        return doneButton
//    }
    
//    open override func prepareLayout(_ imagePickerController: DKImagePickerController, vc: UIViewController) {
//        vc.navigationItem.rightBarButtonItem
//    }
    
//    open override func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type {
//        return CustomGroupDetailImageCell.self
//    }
    
//    open override func imagePickerControllerCollectionVideoCell() -> DKAssetGroupDetailBaseCell.Type {
//        return CustomGroupDetailVideoCell.self
//    }

}
