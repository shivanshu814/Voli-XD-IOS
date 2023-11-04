//
//  LocationViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 25/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation
import GooglePlaces
import RxCocoa
import RxSwift

class LocationViewModel: NSObject, ViewModel {
    var model = [String]()
    let placesClient = GMSPlacesClient.shared()
    var fetcher: GMSAutocompleteFetcher!
    var searchText = BehaviorRelay<String>(value: "")
    var predictions = BehaviorRelay<[Location]>(value: [])
    var cityCenter = BehaviorRelay<CLLocation?>(value:nil)
    var enableCityCenter = false
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    override init() {
        super.init()
        self.configureFetcher()
    }
    
    init(enableCityCenter: Bool) {
        super.init()
        self.enableCityCenter = enableCityCenter
        self.configureFetcher()
    }
}

// MARK: - Public
extension LocationViewModel {
    func fetchPlaces(keyword value: String) {
        if value.isEmpty {
            predictions.accept([])
        } else {            
            fetcher.sourceTextHasChanged(value)
            
        }
    }
    
    func convertToValidLocationFormat(_ placeID: String, completionHandler: @escaping ((city: String, state: String, country: String, fullName: String)?) -> Void) {
        placesClient.lookUpPlaceID(placeID) { (place, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let place = place {
                let _location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                CLGeocoder().reverseGeocodeLocation(_location, preferredLocale: NSLocale(localeIdentifier: "en_US") as Locale) { placemarks, error in
                    
                    if let error = error {
                        print(error.localizedDescription)
                        completionHandler(nil)
                    } else {
                        guard let placeMark = placemarks?[0] else { return }
                                            
                        let location = placeMark.getCityStateCountryName()
                        completionHandler(location)
                    }
                }
            } else {
                completionHandler(nil)
            }
        }
    }
}

// MARK: - Private
extension LocationViewModel {
    private func configureFetcher() {
        let filter = GMSAutocompleteFilter()
        filter.type = .region
        let token: GMSAutocompleteSessionToken = GMSAutocompleteSessionToken.init()
        fetcher = GMSAutocompleteFetcher(bounds: nil, filter: filter)
        fetcher?.delegate = self
        fetcher?.provide(token)
    }
    
    func fetchLocationByPlaceID(_ placeID: String) {
        
        placesClient.lookUpPlaceID(placeID) {[weak self](place, error) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
                let location = CLLocation(latitude: 0, longitude: 0)
                strongSelf.cityCenter.accept(location)
                return
            }
            
            if let place = place {
                // get the center point
                let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                strongSelf.cityCenter.accept(location)
                
            }
        }
    }
    
    func calculateDistance(_ coordinate: CLLocation) -> Int {
        
        if let cityCenter = cityCenter.value, (cityCenter.coordinate.latitude != 0 && cityCenter.coordinate.longitude != 0) {
            return Int(coordinate.distance(from: cityCenter))
        }
        return 99999
    }
}

// MARK: - GMSAutocompleteFetcherDelegate
extension LocationViewModel: GMSAutocompleteFetcherDelegate {
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        let results = predictions.map { (item) -> Location in
            let cc1 = item.attributedPrimaryText.string
            let cc2 = item.attributedSecondaryText?.string ?? ""
            
            return Location(shortName: cc1, longName: cc2.isEmpty ? cc1 : "\(cc1), \(cc2)", placecId: item.placeID)
        }
        
        self.predictions.accept(results)
        if enableCityCenter {
            if let place = predictions.first {
                fetchLocationByPlaceID(place.placeID)
            } else {
                let location = CLLocation(latitude: 0, longitude: 0)
                cityCenter.accept(location)
            }
        }
        
    }
    
    func didFailAutocompleteWithError(_ error: Error) {
        print(error.localizedDescription)
    }
}
