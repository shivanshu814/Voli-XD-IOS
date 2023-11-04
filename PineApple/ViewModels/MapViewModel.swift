//
//  MapViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMapsDirections
import GooglePlaces
import RxCocoa
import RxSwift
import MapKit

class MapViewModel: NSObject, ViewModel {
    // MARK: - Properties
    var itineraryViewModel: ItineraryViewModel
    var locations = [CLLocationCoordinate2D?]()
    var activityViewModels = BehaviorRelay<[ActivityViewModel]>(value: [])
    var selectedActivityIndex: Int    
    let placesClient = GMSPlacesClient.shared()
    var fetcher: GMSAutocompleteFetcher!
    var predictions = BehaviorRelay<[GMSAutocompletePrediction]>(value: [])
    var refreshMarkers = BehaviorRelay<Bool>(value: false)
    var isEditing = false
    var isWalking = true
    private let disposeBag = DisposeBag()
    typealias FetchDirectionBlock = (GoogleMapsDirections.Response.Route) -> Void
    let defaultLocation = CLLocationCoordinate2D(latitude: -33.715846,
                                                longitude: 151.05427)
    
    // MARK: - Init
    init(itineraryViewModel: ItineraryViewModel, selectedActivityIndex: Int, isEditing: Bool = false) {
        self.selectedActivityIndex = selectedActivityIndex
        self.itineraryViewModel = itineraryViewModel
        self.isEditing = isEditing
        super.init()
        var models = itineraryViewModel.activityViewModels
        models.forEach{
            let location = getValidLocation($0.location)
            locations.append(location)
            if !isValidLocation($0.location) {
                $0.locationToString = true
                $0.location = location
            }
            
        }
        if isEditing {
            models.append(ActivityViewModel(activity: Activity.dummyActiviy))
        }
        activityViewModels.accept(models)
        self.configureFetcher()
    }
}

// MARK: - Public
extension MapViewModel {
    
    func undoAll() {
        for (index, location) in locations.enumerated() {
            (itineraryViewModel.rows.value[index+2] as! ActivityViewModel).location = location
        }        
    }
    
    func isValidLocation(_ location: CLLocationCoordinate2D?) -> Bool {
        return location != nil && location!.latitude != 0 && location!.longitude != 0
    }
    
    func getValidLocation(_ location: CLLocationCoordinate2D?) -> CLLocationCoordinate2D{
        return isValidLocation(location) ? location! :  LocationController.shared.location?.coordinate ?? defaultLocation
    }
    
    func location(with index: Int) -> CLLocationCoordinate2D {
        return isValidLocation(activityViewModels.value[index].location) ? activityViewModels.value[index].location! :  LocationController.shared.location?.coordinate ?? defaultLocation
    }
    
    func fetchPlaces(keyword value: String) {
        if value.isEmpty {
            predictions.accept([])
        } else {
            fetcher.sourceTextHasChanged(value)
        }
    }
    
    func fetchLocationByPlaceID(_ placeID: String) {
        
        placesClient.lookUpPlaceID(placeID) {[weak self] (place, error) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let place = place {
                
                let _location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                CLGeocoder().reverseGeocodeLocation(_location, preferredLocale: NSLocale(localeIdentifier: "en_US") as Locale) { placemarks, error in
                    let activityViewModel = (strongSelf.itineraryViewModel.rows.value[strongSelf.selectedActivityIndex+1] as! ActivityViewModel)
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        guard let placeMark = placemarks?[0] else { return }
                                            
                        let location = placeMark.getCityStateCountryName()
                        activityViewModel.city.accept(location.city.isEmpty ? location.state : location.city)
                        activityViewModel.state.accept(location.city.isEmpty ? "" : location.state)
                        activityViewModel.country.accept(location.country)
                    }
                    
                    
                    activityViewModel.locationToString = false
                    activityViewModel.location = place.coordinate
                    activityViewModel.locationString.accept(place.name ?? "")
                    activityViewModel.subLocalityString.accept(place.formattedAddress ?? place.name ?? "")
                    activityViewModel.locationToString = true
                    strongSelf.refreshMarkers.accept(true)
                }
                
                
            }
        }
    }
    
    func fetchDirection(_ completionHandler: @escaping FetchDirectionBlock) {
        guard !isEditing else { return }
        let models = activityViewModels.value[0..<activityViewModels.value.count]
        guard (models.filter{$0.location==nil}).isEmpty else { return }
        
        if let origin = models.first?.location,
            let destination = models.last?.location {
            
            let originCoordinate2D = GoogleMapsDirections.LocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude)
            let destinationCoordinate2D = GoogleMapsDirections.LocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)
            var wayPoints = [GoogleMapsDirections.LocationCoordinate2D]()
            if models.count > 2 {
                wayPoints = models[1..<models.count].map{GoogleMapsDirections.LocationCoordinate2D(latitude:  $0.location!.latitude, longitude: $0.location!.longitude)}
            }
            
            let originPlace = GoogleMapsDirections.Place.coordinate(coordinate: originCoordinate2D)
            let destinationPlace = GoogleMapsDirections.Place.coordinate(coordinate: destinationCoordinate2D)
            let wayPointPlaces = wayPoints.map{GoogleMapsDirections.Place.coordinate(coordinate: $0)}
            
        
            GoogleMapsDirections.direction(fromOrigin: originPlace, toDestination: destinationPlace, travelMode: isWalking ? .walking : .driving, wayPoints: wayPointPlaces.isEmpty ? nil : wayPointPlaces) {(response, error) -> Void in
                guard response?.status == GoogleMapsDirections.StatusCode.ok else { return }
                
                debugPrint("it has \(response?.routes.count ?? 0) routes")
                if response!.routes.count > 0 {
                    let route = response!.routes.first!
                    completionHandler(route)
                }
            }
                
        }
    }
}

// MARK: - Private
extension MapViewModel {
    private func configureFetcher() {
        let token: GMSAutocompleteSessionToken = GMSAutocompleteSessionToken.init()
        let center = location(with: 0)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.0001, center.longitude + 0.0001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.0001, center.longitude - 0.0001)

        let bounds = GMSCoordinateBounds(coordinate: northEast,
                                         coordinate: southWest)
        fetcher = GMSAutocompleteFetcher(bounds: bounds, filter: nil)
        fetcher?.delegate = self
        fetcher?.provide(token) 
    }
}

// MARK: - GMSAutocompleteFetcherDelegate
extension MapViewModel: GMSAutocompleteFetcherDelegate {
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        self.predictions.accept(predictions)
        print(predictions)
    }
    
    func didFailAutocompleteWithError(_ error: Error) {
        print(error.localizedDescription)
    }
}
