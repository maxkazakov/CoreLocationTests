//
//  LocationStorage.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 26.05.2021.
//

import CoreLocation

class LocationsStorage {
    var allLocations: [LocationInfo] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.locationsDidUpdate, object: nil)
        }
    }
    var allErrors: [Error] = []
    
    var locations: [CLLocation] {
        allLocations.map { $0.location }
    }
    
    static let shared = LocationsStorage()
    
    func clear() {
        allLocations.removeAll()
        allErrors.removeAll()
    }
}
