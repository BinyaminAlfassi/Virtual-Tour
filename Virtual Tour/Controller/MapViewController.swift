//
//  MapViewController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager!
    
    var autosaveRegionFlag = true
    
    var fetchResultsController: NSFetchedResultsController<Pin>!
    
    let locationDetailsVCSegue = "LocationDetailsVCSegue"
    
    var pins: [Pin] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setGestureRecognition()
        setLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateMapWithAnnotations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutosaveRegion(start: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        startAutosaveRegion(start: false)
        saveMapLocation()
    }
    
    func setGestureRecognition() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    func setLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            initiateLocationManager()
            configureLocationAuthorization()
            setInitialRegion()
        }
    }
    
    fileprivate func initiateLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    fileprivate func configureLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // show alert
            break
        default:
            break
        }
    }
    
    func populateMapWithAnnotations() {
        DataController.shared.viewContext.perform {
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            self.fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
            self.fetchResultsController.delegate = self
            do {
                try self.fetchResultsController.performFetch()
            } catch {
                fatalError("Fetching user pins could not perform: \(error.localizedDescription)")
            }
            self.pins = self.fetchResultsController.fetchedObjects ?? []
            for pin in  self.pins {
                self.addAnnotationToMap(latitude: pin.latitude, longitude: pin.longitude)
            }
            
        }
    }
    
    func fetchPin(latitde: CLLocationDegrees, longitude: CLLocationDegrees) -> Pin? {
        for pin in self.pins {
            if (pin.latitude == latitde) && (pin.longitude == longitude) {
                return pin
            }
        }
        return nil
        
    }
}

extension MapViewController {
    func setInitialRegion() {
        if UserDefaults.standard.bool(forKey: DataController.VTUserDefaults.initialLocationHasSet.rawValue) {
            let lastLatitude = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLatitude.rawValue) as! CLLocationDegrees
            let lastLongitude = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLongitude.rawValue) as! CLLocationDegrees
            let lastLatitudeDelta = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLatitudeDelta.rawValue) as! CLLocationDegrees
            let lastLongitudeDelta = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLongitudeDelta.rawValue) as! CLLocationDegrees
            
            let lastCoordinate = CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
            let lastSpan = MKCoordinateSpan(latitudeDelta: lastLatitudeDelta, longitudeDelta: lastLongitudeDelta)
            
            let region = MKCoordinateRegion(center: lastCoordinate, span: lastSpan)
            mapView.setRegion(region, animated: true)
        } else {
            saveMapLocation()
            UserDefaults.standard.setValue(true, forKey: DataController.VTUserDefaults.initialLocationHasSet.rawValue)
        }
    }
    
    func saveMapLocation() {
        let (lat, long, latDelta, longDelta): (CLLocationDegrees, CLLocationDegrees, CLLocationDegrees, CLLocationDegrees) = getCurrentMapRegion()
        
        UserDefaults.standard.setValue(lat, forKey: DataController.VTUserDefaults.mapLastLocationLatitude.rawValue)
        UserDefaults.standard.setValue(long, forKey: DataController.VTUserDefaults.mapLastLocationLongitude.rawValue)
        UserDefaults.standard.setValue(latDelta, forKey: DataController.VTUserDefaults.mapLastLocationLatitudeDelta.rawValue)
        UserDefaults.standard.setValue(longDelta, forKey: DataController.VTUserDefaults.mapLastLocationLongitudeDelta.rawValue)
    }
    
    func getCurrentMapRegion() -> (CLLocationDegrees, CLLocationDegrees, CLLocationDegrees, CLLocationDegrees) {
        let lat = mapView.region.center.latitude
        let long = mapView.region.center.longitude
        let latDelta = mapView.region.span.latitudeDelta
        let longDelta = mapView.region.span.longitudeDelta
        return (lat, long, latDelta, longDelta)
    }
    
    func autosaveMapRegion(interval: TimeInterval = 30) {
        print("Autosaving Region...")
        guard interval > 0 else {
            print("Cannot set negative interval")
            return
        }
        self.saveMapLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveMapRegion()
        }
    }
    
    func startAutosaveRegion(start: Bool) {
        if start {
            autosaveRegionFlag = true
            autosaveMapRegion()
        } else {
            autosaveRegionFlag = false
        }
    }
}

extension MapViewController {
    
    @objc func longTap(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.ended:
            // Getting current location
            let currentLocation = gestureRecognizer.location(in: mapView)
            // Getting coordinate of current location
            let currentCoordinate = mapView.convert(currentLocation, toCoordinateFrom: mapView)
            addPinToDB(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        default:
            break
        }
    }
    
    func addPinToDB(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        DataController.shared.viewContext.perform {
            let newPin: Pin = Pin(context: DataController.shared.viewContext)
            newPin.latitude = latitude
            newPin.longitude = longitude
            newPin.photo = nil
            do {
                try DataController.shared.viewContext.save()
                self.pins.append(newPin)
            } catch {
                // TBD: show message to user
            }
        }
    }
    
    func addAnnotationToMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
    }
}

extension MapViewController {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let point = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instance")
        }
        
        switch type {
        case .insert:
            addAnnotationToMap(latitude: point.latitude, longitude: point.longitude)
        default:
            break
        }
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = mapView.selectedAnnotations[0]
        let lat = annotation.coordinate.latitude
        let long = annotation.coordinate.longitude
        
        let pin = fetchPin(latitde: lat, longitude: long)
        if let pin = pin {
            self.performSegue(withIdentifier: locationDetailsVCSegue, sender: pin)
//            let locationDetailsVC = storyboard?.instantiateViewController(identifier: locationDetailsVCID) as! LocationDetailsViewController
//            locationDetailsVC.pin = pin
//            present(locationDetailsVC, animated: true, completion: nil)
        } else {
            // TBD: show message that pin didn't found
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LocationDetailsViewController {
            vc.pin = (sender as! Pin)
        }
    }
}
