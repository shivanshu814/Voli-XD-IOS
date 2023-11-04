//
//  AVPlayerViewController+Extension.swift
//  Voli XD
//
//  Created by Tao Man Kit on 18/12/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import AVKit

extension AVPlayerViewController {
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()
        NotificationCenter.default.post(name: Notification.Name("avPlayerDidDismiss"), object: nil, userInfo: nil)
    }
}
