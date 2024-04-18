//
//  LocationManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/20.
//

import Foundation
@_implementationOnly import MapboxCoreNavigation
@_implementationOnly import MapboxNavigation
import CoreLocation

public protocol MBLocationManagerDelegate : NSObjectProtocol {
    func didUpdateLocation(model: LocationModel)
    func didUpdateSpeedLimit(speedLimit: Double?)
}

class LocationManager: NSObject, PassiveLocationManagerDelegate {
    public var locationModel: LocationModel?
    public var speedLimit: Double = 0
    public var isLocation: Bool = false
    public var isUpdating: Bool = false
    public var isSpeedOver: Bool = false
    public var delegate: MBLocationManagerDelegate!
    
    private let passiveLocationManager = PassiveLocationManager()
    private lazy var passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
//    private var locationManager: CLLocationManager!
    private var isInUse: Bool = true
    
    static let shared = LocationManager()
    
    override init() {
        super.init()
        passiveLocationManager.systemLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        passiveLocationManager.systemLocationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager = CLLocationManager.init()
//        if (CLLocationManager.locationServicesEnabled()) {
//            print("locationServicesEnabled true");
//            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//            self.locationManager.distanceFilter = kCLDistanceFilterNone;
//            self.locationManager.delegate = self;
//        }
//        else {
//            MTAlert.showAlertWithTitle(title: "Tips", message: "Location services not available")
//            print("locationServicesEnabled false");
//        }
    }
    
    func checkSpeedOver() {
        if (self.locationModel == nil || self.locationModel?.speed == nil) {
            return
        }
        let speed = Double((self.locationModel?.speed)!)!
        if (speedLimit > 0 && speed > speedLimit) {
            self.isSpeedOver = true
        }
        else {
            self.isSpeedOver = false
        }
    }
    
    //CLLocationManagerDelegate
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if (locations.count > 0) {
//            let location = locations.last!
//            updateLocation(location: location)
//            let speed = max(location.speed, 0)
//            print("didUpdateLocations \(location.speed) \(location.coordinate.latitude) \(location.coordinate.longitude)")
//            if (self.locationModel == nil) {
//                self.locationModel = LocationModel.init()
//            }
//            self.locationModel!.latitude = location.coordinate.latitude
//            self.locationModel!.longitude = location.coordinate.longitude
//            self.locationModel!.course = location.course
//            self.locationModel!.altitude = location.altitude
//            self.locationModel!.speed = String(Int(round(speed*3.6)))
//            self.checkSpeedOver()
//            self.delegate?.didUpdateLocation(model: self.locationModel!)
//            self.isLocation = true
//        }
//    }
    
    func updateLocation(location: CLLocation) {
        let speed = max(location.speed, 0)
        print("didUpdateLocations \(location.speed) \(location.coordinate.latitude) \(location.coordinate.longitude)")
        if (self.locationModel == nil) {
            self.locationModel = LocationModel.init()
        }
        self.locationModel!.latitude = location.coordinate.latitude
        self.locationModel!.longitude = location.coordinate.longitude
        self.locationModel!.course = location.course
        self.locationModel!.altitude = location.altitude
        self.locationModel!.speedValue = Int(round(speed*3.6))
        self.locationModel!.speed = String(Int(round(speed*3.6)))
        self.checkSpeedOver()
        self.isLocation = true
        self.delegate?.didUpdateLocation(model: self.locationModel!)
    }
    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Location Fail")
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        if (locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways) {
//            requestAlwaysAuth()
//        }
//    }
//
    public func requestAlwaysAuth() {
        if (passiveLocationProvider.authorizationStatus == .authorizedWhenInUse && !isInUse) {
            passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
            passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
            passiveLocationProvider.requestAlwaysAuthorization()
        }
        startLocation()
    }
    
    public func startLocationWithAuth(inUse: Bool=true) {
        isInUse = inUse
        print("locationManager.authorizationStatus=\(passiveLocationProvider.authorizationStatus.rawValue)")
        if (passiveLocationProvider.authorizationStatus == .notDetermined) {
            if (inUse) {
                passiveLocationProvider.requestWhenInUseAuthorization()
            }
            else {
                passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
                passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
                passiveLocationProvider.requestAlwaysAuthorization()
            }
            startLocation()
        }
        else if (passiveLocationProvider.authorizationStatus == .denied || passiveLocationProvider.authorizationStatus == .restricted) {
            MTAlert.showAlertWithTitle(title: "Tips", message: "Location denied authorization")
        }
        else {
            requestAlwaysAuth()
        }
    }
    
    public func startLocation() {
        if (isUpdating) {
            return
        }
        print("startUpdatingLocation")
        isUpdating = true
//        locationManager.startUpdatingLocation()
        passiveLocationManager.delegate = self
        passiveLocationProvider.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePassiveLocation), name: Notification.Name.passiveLocationManagerDidUpdate, object: nil)
    }
    
    public func stopLocation() {
        self.isLocation = false
        print("stopUpdatingLocation")
        isUpdating = false
//        locationManager.stopUpdatingLocation()
        passiveLocationManager.delegate = nil
        passiveLocationProvider.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.passiveLocationManagerDidUpdate, object: nil)
    }
    
    //PassiveLocationManagerDelegate
    func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        print("passiveLocationManagerDidChangeAuthorization")
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        updateLocation(location: location)
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
//        let locationObj = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey]
//        if (locationObj != nil) {
//            let location = locationObj as! CLLocation
//        }
//        print("didUpdatePassiveLocation:", notification.userInfo!)
        let speedLimitObj = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey]
        if (speedLimitObj != nil) {
            let speedLimit: Measurement<UnitSpeed> = speedLimitObj! as! Measurement<UnitSpeed>
            print("speedLimit:", speedLimit, speedLimit.value, speedLimit.unit)
            self.speedLimit = speedLimit.value
            if (speedLimit.unit == UnitSpeed.metersPerSecond) {
                self.speedLimit = speedLimit.value*3.6
            }
            self.checkSpeedOver()
            self.delegate?.didUpdateSpeedLimit(speedLimit: self.speedLimit)
        }
        else {
            self.speedLimit = 0.0
            self.delegate?.didUpdateSpeedLimit(speedLimit: 0.0)
        }
    }
}
