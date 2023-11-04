//
//  RequestStatus.swift
//  ATOMIC
//
//  Created by Tao Man Kit on 29/1/2020.
//  Copyright © 2020 ATOMIC. All rights reserved.
//

import Foundation

enum RequestStatus {
    case none
    case processing
    case success
    case failure(error: String)
}
