//
//  ViewController.swift
//  SunriseSunsetApp
//
//  Created by Володимир Ільків on 12/28/18.
//  Copyright © 2018 Володимр Ільків. All rights reserved.
//

import UIKit
import CoreLocation
import GooglePlaces

class ViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var countryLabel: UILabel!
    @IBOutlet private weak var sunriseLabel: UILabel!
    @IBOutlet private weak var sunsetLabel: UILabel!
    
    fileprivate var resultsViewController  : GMSAutocompleteResultsViewController?
    fileprivate var searchController : UISearchController?
    fileprivate let locationManager = CLLocationManager()
    public var sunPositionInfo : SunPositionInfo!
    fileprivate var latitude : Double!
    fileprivate var longitude : Double!
    private var timeZone : TimeZone?
    fileprivate var location : CLLocation! {
        didSet{
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCoreLocationPermission()
        setupLocationManager()
        setupSearchBar()
    }
    
    private func setupLocationManager(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
    
    
    private func setupSearchBar(){
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        searchController?.searchBar.sizeToFit()
        navigationItem.titleView = searchController?.searchBar
        
        view.addSubview((searchController?.searchBar)!)
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
    }
    
    private func checkCoreLocationPermission() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if CLLocationManager.authorizationStatus() == .restricted {
            print("unauthorized to use location service")
        }
    }
    
    fileprivate func countryCityName(location: CLLocation) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil {
                var placemark: CLPlacemark!
                placemark = placemarks![0]
                if let city = placemark?.locality {
                    self.cityLabel.text = String(city)
                } else {
                    self.cityLabel.text = "City didn't found"
                }
                if let time = placemarks?.last?.timeZone{
                    self.timeZone = time
                    
                }else{
                    print("didnt get time")
                }
                if let country = placemark?.country {
                    self.countryLabel.text = String(country)
                } else {
                    self.countryLabel.text = "Country didn't found"
                }
            }
        }
    }
    
    fileprivate func updateSunInformationForLocation(currentLocation: String) {
        CLGeocoder().geocodeAddressString(currentLocation) { (placemarks: [CLPlacemark]? , error: Error?) in
            if error == nil {
                if let location = placemarks?.first?.location {
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    self.timeZone = placemarks?.first?.timeZone
                    SunInfoService.shared.getSunPositionInfo(latitude: latitude, longitude: longitude, completion: { (result) in
                        if let sunInformationData = result {
                            self.sunPositionInfo = sunInformationData
                            DispatchQueue.main.async {
                                self.updateLabel(info: self.sunPositionInfo, location: location)
                            }
                        }
                    })
                }
            }
        }
    }
    
    fileprivate func getSunInformationOnlyWithCoordinate(latitude: Double, longitude: Double) {
        SunInfoService.shared.getSunPositionInfo(latitude: latitude, longitude: longitude, completion: { (result) in
            if let sunInformationData = result {
                self.sunPositionInfo = sunInformationData
                DispatchQueue.main.async{
                    self.updateLabel(info: self.sunPositionInfo, location: self.location)
                }
            }
        })
    }
    
    private func updateLabel(info: SunPositionInfo, location: CLLocation) {
        countryCityName(location: location)
        sunsetLabel.text = convertDate(date: info.sunset!)
        sunriseLabel.text = convertDate(date: info.sunrise!)
        
    }
    
    private func loadFirstPhotoForPlace(placeID: String) {
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { (photos, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(photoMetadata: firstPhoto)
                }
            }
        }
    }
    
    private func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: {
            (photo, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                self.imageView.image = photo
            }
        })
    }
    
    private func convertDate(date : String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let dt = dateFormatter.date(from: date) {
            dateFormatter.timeZone = timeZone
            dateFormatter.dateFormat = "HH:mm:ss"
            
            return dateFormatter.string(from: dt)
        } else {
            return "Unknown date"
        }
        
    }
    
    
}

extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        updateSunInformationForLocation(currentLocation: "\(place.name)")
        loadFirstPhotoForPlace(placeID: place.placeID)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        print("Error: ", error.localizedDescription)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        locationManager.stopUpdatingLocation()
        if latitude != nil, longitude != nil {
            getSunInformationOnlyWithCoordinate(latitude: latitude, longitude: longitude)
        }
        countryCityName(location: location)
    }
}
