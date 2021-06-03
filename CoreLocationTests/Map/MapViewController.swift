//
//  ListLocationsViewController.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 04.05.2021.
//

import UIKit
import MapKit
import CoreLocation

extension Notification.Name {
    static let locationsDidUpdate = Notification.Name(rawValue: "locationDidUpdate")
    static let enterRegion = Notification.Name(rawValue: "enterRegion")
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var removePizzeriaButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startStopTracking: UIButton!
    @IBOutlet weak var mappin: UIImageView!
    
    private var pizzeriaAnnotation: MKAnnotation?
    private var pizzeriaCoordinate: CLLocationCoordinate2D?
    private let pizzeriaRadius: CLLocationDistance = 100.0
    private let pizzeriaRegionIdentifier = "pizzeriaRegionIdentifier"
    private var isStarted = false
        
    private lazy var locationManager = CLLocationManager()
    private let mapZoomEdgeInsets = UIEdgeInsets(top: 30.0, left: 30.0, bottom: 30.0, right: 30.0)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 7 //kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = .other
        locationManager.pausesLocationUpdatesAutomatically = false
                
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        mappin.isHidden = true
        
        // draw on map
        if let monotiredRegion = getMonitoredRegion() {
            let coordinate = monotiredRegion.center
            addAnnotation(coordinate: coordinate)
            addRadiusOverlay(coorditate: coordinate)
            self.pizzeriaCoordinate = coordinate
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.enterRegion,
            object: nil,
            queue: nil,
            using: { _ in
                self.locationManager.startUpdatingLocation()
            }
        )
    }
    
    // MARK: - Actions
    @IBOutlet weak var startSignificantButton: UIButton!
    
//    @IBAction func onStartSignificantLocationUpdates(_ sender: Any) {
//        locationManager.startMonitoringSignificantLocationChanges()
//    }
    
    
    @IBAction func showMe(_ sender: Any) {
        showAndZoomCurrent()
    }
    
    @IBAction func onClearAllLocations(_ sender: Any) {
        LocationsStorage.shared.clear()
    }
    
    @IBAction func onRemovePizzeria(_ sender: Any) {
        removeCurrentPizzera()
    }
    
    @IBAction func onStartOrStop(_ sender: Any) {
        defer {
            isStarted = !isStarted
        }
        if isStarted {
            startStopTracking.setTitle("Start Tracking", for: .normal)
            locationManager.stopUpdatingLocation()
        } else {
            startStopTracking.setTitle("Stop Tracking", for: .normal)
            locationManager.startUpdatingLocation()
        }
    }
        
    @IBOutlet weak var addPizzeriaButton: UIButton!
    var isAddingPizzeria = false
    
    @IBAction func onAddPizzeria(_ sender: Any) {
        if isAddingPizzeria {
            mappin.isHidden = true
            removePizzeriaButton.isHidden = false
            addPizzeriaButton.setTitle("Add Pizzeria", for: .normal)
            let coordinate = mapView.centerCoordinate
            let pizzeriaLocation = CLLocation(
                coordinate: coordinate,
                altitude: -1,
                horizontalAccuracy: -1,
                verticalAccuracy: -1,
                timestamp: Date()
            )
            addPizzeria(pizzeiaLocation: pizzeriaLocation)
        } else {
            mappin.isHidden = false
            removePizzeriaButton.isHidden = false
            addPizzeriaButton.setTitle("HERE!", for: .normal)
        }
        isAddingPizzeria = !isAddingPizzeria
    }
    
    
    private func addPizzeria(pizzeiaLocation: CLLocation) {
        self.dismiss(animated: true, completion: nil)
        let pizzeriaCoordinateNew = pizzeiaLocation.coordinate
        
        // Remove old
        removeCurrentPizzera()
        
        // Add new
        startMonitoring(coorditate: pizzeriaCoordinateNew)
        addAnnotation(coordinate: pizzeriaCoordinateNew)
        addRadiusOverlay(coorditate: pizzeriaCoordinateNew)
        
        self.pizzeriaCoordinate = pizzeriaCoordinateNew
    }
    
    // Radius
    func addRadiusOverlay(coorditate: CLLocationCoordinate2D) {
        mapView.addOverlay(MKCircle(center: coorditate, radius: pizzeriaRadius))
    }
    
    func removeRadiusOverlay() {
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            mapView.removeOverlay(circleOverlay)
        }
    }
    
    func getMonitoredRegion() -> CLCircularRegion? {
        for region in locationManager.monitoredRegions {
            guard
                let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == pizzeriaRegionIdentifier
            else { continue }
            return circularRegion
        }
        return nil
    }
    
    func removePizzeriaRegion() {
        removeAnnotation()
        removeRadiusOverlay()
        self.pizzeriaAnnotation = nil
        self.pizzeriaCoordinate = nil
    }    
    
    // Monitoring
    func stopMonitoringRegion(coorditate: CLLocationCoordinate2D) {
        guard let circularRegion = getMonitoredRegion() else {
            return
        }
        removeRadiusOverlay()
        locationManager.stopMonitoring(for: circularRegion)
    }
    
    func startMonitoring(coorditate: CLLocationCoordinate2D) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(
                withTitle: "Error",
                message: "Geofencing is not supported on this device!")
            return
        }
        let region = CLCircularRegion(center: coorditate, radius: pizzeriaRadius, identifier: pizzeriaRegionIdentifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        locationManager.startMonitoring(for: region)
    }
    
    // Annotation
    private func removeAnnotation() {
        if let oldAnnotation = pizzeriaAnnotation {
            mapView.removeAnnotation(oldAnnotation)
            pizzeriaAnnotation = nil
        }
    }
        
    private func addAnnotation(coordinate: CLLocationCoordinate2D) {
        let pizzeriaAnnotation = MKPointAnnotation()
        pizzeriaAnnotation.coordinate = coordinate
        mapView.addAnnotation(pizzeriaAnnotation)
        self.pizzeriaAnnotation = pizzeriaAnnotation
    }
    
    private func removeCurrentPizzera() {
        removeAnnotation()
        removeRadiusOverlay()
        if let pizzeriaLocation = pizzeriaCoordinate {
            stopMonitoringRegion(coorditate: pizzeriaLocation)
        }
    }

    private func updateOverlays() {
        let locations = LocationsStorage.shared.allLocations.map { $0.location.coordinate }
        
        if let polyline = mapView.overlays.first(where: { $0 is MKPolyline }) as? MKPolyline {
            mapView.removeOverlay(polyline)
        }
        
        let polyline = MKPolyline(coordinates: locations, count: locations.count)
        mapView.addOverlay(polyline)
    }
    
    private func updateRemovePizzeriaButton() {
        self.removePizzeriaButton.isHidden = pizzeriaAnnotation == nil
    }
    
    private func showAndZoomCurrent() {
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: false)
        }
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.orange
        renderer.lineWidth = 3.0
        return renderer
    }
}


extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let filteredLocations = filter(locations: locations)
        guard filteredLocations.count > 0 else {
            return
        }
        let appState = UIApplication.shared.applicationState
        
        for location in filteredLocations {
            var toPizzeriaInfo: LocationInfo.PizzeriaRelated?
            
            if let pizzeriaCoordinate = self.pizzeriaCoordinate {
                let pizzeriaLocation = CLLocation(coordinate: pizzeriaCoordinate, altitude: 0, horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: Date())
                let distanceToPizzeria = pizzeriaLocation.distance(from: location)
                var pizzeiaInfo = LocationInfo.PizzeriaRelated(distanceToPizzeria: distanceToPizzeria)
                
                if let movingPace100m = movingPace(locations: LocationsStorage.shared.locations, meters: 100),
                   movingPace100m > 0 {
                    let timeToCome = distanceToPizzeria / movingPace100m
                    pizzeiaInfo.movingPace = movingPace100m
                    pizzeiaInfo.timeToCome = timeToCome
                }
                toPizzeriaInfo = pizzeiaInfo
            }
            
            let newLocation = LocationInfo(
                location: location,
                appState: appState,
                pizzeriaRelatedInfo: toPizzeriaInfo
            )
            LocationsStorage.shared.allLocations.append(newLocation)
        }
        
        updateOverlays()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LocationsStorage.shared.allErrors.append(error)
    }
    
    private func filter(locations: [CLLocation]) -> [CLLocation] {
        locations.filter { newLocation in
            let howRecent = abs(newLocation.timestamp.timeIntervalSinceNow)
            guard newLocation.horizontalAccuracy > 0,
                  newLocation.horizontalAccuracy < 50,
                  abs(howRecent) < 10 else {
                return false
            }
            return true
        }
    }
    public func movingPace(locations: [CLLocation], meters: Double) -> Double? {
        guard locations.count > 1 else {
            return nil
        }
        let lastLocation = locations.last!
        var sumDistance = 0.0
        for idx in (1...locations.count - 1).reversed() {
            let last = locations[idx]
            let beforeLast = locations[idx - 1]
            let distance = last.distance(from: beforeLast)
            sumDistance += distance
            if sumDistance > meters {
                let seconds = lastLocation.timestamp.timeIntervalSince1970 - beforeLast.timestamp.timeIntervalSince1970
                let metersPerSecond = sumDistance / seconds
                return metersPerSecond
            }
        }
        return nil
    }
}
