//
//  LocationController.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation
import GooglePlaces
import GoogleMaps
import MapKit

class LocationController: NSObject {
    
    // MARK: - Properties
    static let shared = LocationController()
    let locationManager = CLLocationManager()
    var locationForCreatingAcc = false
    var location: CLLocation? {
        return locationManager.location
    }
    var locationInfo: (city: String, state: String, country: String, fullName: String)?
    
    // MARK: - Init
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
    }
    
}

// MARK: - Public
extension LocationController {
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCityCountry(_ completionHandler: @escaping ((city: String, state: String, country: String, fullName: String)) -> Void) {
        if let _location = location {
            
            CLGeocoder().reverseGeocodeLocation(_location, preferredLocale: NSLocale(localeIdentifier: "en_US") as Locale) {placemarks, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    guard let placeMark = placemarks?[0] else { return }
                    completionHandler(placeMark.getCityStateCountryName())
                }
            }
        } else {
            completionHandler(("","","",""))
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension LocationController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        NotificationCenter.default.post(name: .locationPermissionDidChanged, object: nil)
        
        if locationInfo == nil {
            LocationController.shared.getCityCountry {[weak self] (info) in
                self?.locationInfo = info
                NotificationCenter.default.post(name: .locationUpdated, object: nil)                
            }
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            Globals.topViewController.showLocationPermissionAlert(locationForCreatingAcc)
            locationForCreatingAcc = false
            NotificationCenter.default.post(name: .locationUpdated, object: nil)
        case .notDetermined: break
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:  
            print("Location status is OK.")
            NotificationCenter.default.post(name: .locationPermissionDidChanged, object: nil)
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
        NotificationCenter.default.post(name: .locationUpdated, object: nil)
    }
}



//            GMSGeocoder().reverseGeocodeCoordinate(_location.coordinate) { response, error in
//                guard let address = response?.firstResult() else {
//                    completionHandler("")
//                    return
//                }
//                let city = "\(address.locality ?? address.administrativeArea ?? "")"
//                let state = address.administrativeArea == city ? "" : address.administrativeArea ?? ""
//                let shortState = state.split(separator: " ").map { String($0.first!) }.joined()
////                completionHandler("\(city.isEmpty || address.country == "Hong Kong" ? "" : "\(city), ")\(address.country ?? "")")
//
//                completionHandler("\(city.isEmpty || address.country == "Hong Kong" ? "" : "\(city), ")\(state.isEmpty ? "": "\(shortState), ")\(address.country ?? "")")
//            }
