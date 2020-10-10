//
//  MapViewController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import UIKit
import MapKit
import CoreData
//MARK: Class representing Map view as the first view of the App
class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    //MARK: Outlets & variables
    //MARK: Map related variables
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    //MARK: Helping variables
    // Autosave flag - used to initiate and stoping autosave of Map Region
    var autosaveRegionFlag = true
    // FetchResultsControoler used to automaticaly handle syncronization between View and Database
    var fetchResultsController: NSFetchedResultsController<Pin>!
    // ID of segue
    let locationDetailsVCSegue = "LocationDetailsVCSegue"
    
    var pins: [Pin] = []
    //MARK: Methods
    // This function will be called after view loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setGestureRecognition()
        setLocationServices()
    }
    // Before view appears the map will be papulated with stored annotations
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateMapWithAnnotations()
    }
    // After view appears app start autosaving of map regioin
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutosaveRegion(start: true)
    }
    // Before view disappear app stops autosaving of map region and manualy save it
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        startAutosaveRegion(start: false)
        saveMapLocation()
    }
    //MARK: Configurations Methods
    // Configuring Gesture Recognition to handle with long press on the map
    func setGestureRecognition() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    // Configuring location services
    func setLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            initiateLocationManager()
            configureLocationAuthorization()
            setInitialRegion()
        }
    }
    // Initiating location services
    fileprivate func initiateLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    // Configuring Location Authorization
    fileprivate func configureLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            // Has authorization --> Updating location
            locationManager.startUpdatingLocation()
        case .notDetermined:
            // Not determined yet --> requesting authorization from user
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // TBD show alert
            break
        default:
            break
        }
    }
    //MARK: Utilities methods
    //Populating map with Pins stored in previous runs
    func populateMapWithAnnotations() {
        DataController.shared.viewContext.perform {
            // Creating a fetch request
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            // Sort Descriptor set as latitude
            let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            // Initiating FetchRequestController
            self.fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
            // Setting its delegate
            self.fetchResultsController.delegate = self
            // Fetching all stored pins
            do {
                try self.fetchResultsController.performFetch()
            } catch {
                fatalError("Fetching user pins could not perform: \(error.localizedDescription)")
            }
            // Storing Pins
            self.pins = self.fetchResultsController.fetchedObjects ?? []
            // Adding pins to map as annotations
            for pin in  self.pins {
                self.addAnnotationToMap(latitude: pin.latitude, longitude: pin.longitude)
            }
        }
    }
    // This method retures a pin with same latitude and longitude
    func getPin(latitde: CLLocationDegrees, longitude: CLLocationDegrees) -> Pin? {
        for pin in self.pins {
            if (pin.latitude == latitde) && (pin.longitude == longitude) {
                return pin
            }
        }
        return nil
        
    }
}
//MARK: Extensions
//MARK: Extention providing utilities to handle map related operations
extension MapViewController {
    // Setting initial region if was stored already
    func setInitialRegion() {
        // Check if there is already region stored in UserDefaults
        if UserDefaults.standard.bool(forKey: DataController.VTUserDefaults.initialLocationHasSet.rawValue) {
            // Getting relevant data
            let lastLatitude = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLatitude.rawValue) as! CLLocationDegrees
            let lastLongitude = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLongitude.rawValue) as! CLLocationDegrees
            let lastLatitudeDelta = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLatitudeDelta.rawValue) as! CLLocationDegrees
            let lastLongitudeDelta = UserDefaults.standard.value(forKey: DataController.VTUserDefaults.mapLastLocationLongitudeDelta.rawValue) as! CLLocationDegrees
            
            let lastCoordinate = CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
            let lastSpan = MKCoordinateSpan(latitudeDelta: lastLatitudeDelta, longitudeDelta: lastLongitudeDelta)
            // creating region
            let region = MKCoordinateRegion(center: lastCoordinate, span: lastSpan)
            // Setting region
            mapView.setRegion(region, animated: true)
        } else {
            // There was no region stored
            // Saving the region
            saveMapLocation()
            // Saving indication in UserDefauls that a region has been stored
            UserDefaults.standard.setValue(true, forKey: DataController.VTUserDefaults.initialLocationHasSet.rawValue)
        }
    }
    // This function saving map region in UserDefaults
    func saveMapLocation() {
        // Getting current region
        let (lat, long, latDelta, longDelta): (CLLocationDegrees, CLLocationDegrees, CLLocationDegrees, CLLocationDegrees) = getCurrentMapRegion()
        // Storing region in UserDefaults
        UserDefaults.standard.setValue(lat, forKey: DataController.VTUserDefaults.mapLastLocationLatitude.rawValue)
        UserDefaults.standard.setValue(long, forKey: DataController.VTUserDefaults.mapLastLocationLongitude.rawValue)
        UserDefaults.standard.setValue(latDelta, forKey: DataController.VTUserDefaults.mapLastLocationLatitudeDelta.rawValue)
        UserDefaults.standard.setValue(longDelta, forKey: DataController.VTUserDefaults.mapLastLocationLongitudeDelta.rawValue)
    }
    // This method returns parameters representing current map region
    func getCurrentMapRegion() -> (CLLocationDegrees, CLLocationDegrees, CLLocationDegrees, CLLocationDegrees) {
        let lat = mapView.region.center.latitude
        let long = mapView.region.center.longitude
        let latDelta = mapView.region.span.latitudeDelta
        let longDelta = mapView.region.span.longitudeDelta
        return (lat, long, latDelta, longDelta)
    }
    // This function autosave map region to UserDefaults until stopped by indication of autosaveRegionFlag
    func autosaveMapRegion(interval: TimeInterval = 30) {
        print("Autosaving Region...")
        guard interval > 0 else {
            print("Cannot set negative interval")
            return
        }
        guard autosaveRegionFlag else {
            print("Stoping Autosaving Region")
            return
        }
        self.saveMapLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveMapRegion()
        }
    }
    // Starting/Stoping autosave of map region
    func startAutosaveRegion(start: Bool) {
        if start {
            autosaveRegionFlag = true
            autosaveMapRegion()
        } else {
            autosaveRegionFlag = false
        }
    }
}

//MARK: extention providing operations of adding Pins and annotations
extension MapViewController {
    // This method handle long tap of the map to add a Pin to DB and eventually (automatically) to map
    @objc func longTap(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.ended:
            // Getting current location
            let currentLocation = gestureRecognizer.location(in: mapView)
            // Getting coordinate of current location
            let currentCoordinate = mapView.convert(currentLocation, toCoordinateFrom: mapView)
            // Adding the pin to DB
            addPinToDB(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        default:
            break
        }
    }
    // This method add a pin to database
    func addPinToDB(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        DataController.shared.viewContext.perform {
            // Creating a pin
            let newPin: Pin = Pin(context: DataController.shared.viewContext)
            // Setting its variables
            newPin.latitude = latitude
            newPin.longitude = longitude
            newPin.photo = nil
            do {
                // Savomg the pin to DB
                try DataController.shared.viewContext.save()
                // Storing it in pin list of view
                self.pins.append(newPin)
            } catch {
                // TBD: show message to user
            }
        }
    }
    // This method add annotation to map according to given location
    func addAnnotationToMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // Creating annotation
        let annotation = MKPointAnnotation()
        // Setting its variables
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        // Adding annotation to map
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
    }
}

//MARK: Extensioni providing automatic update of the map according to DB
extension MapViewController {
    // This method called when there was a change in DB
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // getting the pin
        guard let point = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instance")
        }
        // Adding the pin to map
        switch type {
        case .insert:
            addAnnotationToMap(latitude: point.latitude, longitude: point.longitude)
        default:
            break
        }
    }
}

//MARK: Extention providing Map and DB synchronization operations
extension MapViewController: NSFetchedResultsControllerDelegate {
    // This method is called to add annotation to map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        // dequeing annotation
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        // If annotationView is empty - Creating one
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    // This method handles taping on a pin in the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Getting the correct annotation
        let annotation = mapView.selectedAnnotations[0]
        // Getting location
        let lat = annotation.coordinate.latitude
        let long = annotation.coordinate.longitude
        // Getting the Pin according to location
        let pin = getPin(latitde: lat, longitude: long)
        // Performing segue to LocationDetailsViewController
        if let pin = pin {
            self.performSegue(withIdentifier: locationDetailsVCSegue, sender: pin)
        } else {
            // TBD: show message that pin didn't found
        }
    }
    // Prepare method to set locationDetailViewController with relevant Pin from DB
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LocationDetailsViewController {
            vc.pin = (sender as! Pin)
        }
    }
}
