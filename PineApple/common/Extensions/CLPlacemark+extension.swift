//
//  CLPlacemark+extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 17/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension CLPlacemark {
    func getCityStateCountryName() -> (city: String, state: String, country: String, fullName: String) {
        var city = subAdministrativeArea ?? ""
        var state = administrativeArea ?? ""
        var country = (self.country ?? "")
        if country.lowercased().starts(with: "hong kong") {
            country = "Hong Kong"
            city = "Hong Kong"
            state = ""
        } else if country.lowercased().starts(with: "china") {
            city = locality ?? state
            if state == city {
                state = ""
            }
        } else if city.isEmpty && !state.isEmpty {
            city = state
            state = ""
        }
        
        let fullName = country.lowercased() == "hong kong" ? country : "\(city.isEmpty ? "" : "\(city), ")\(state.isEmpty ? "": "\(state), ")\(country)"
        return (city.lowercased(), state.lowercased(), country.lowercased(), fullName)
    }
}
