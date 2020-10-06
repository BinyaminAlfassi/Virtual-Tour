//
//  LocationDetailsViewController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import UIKit
import MapKit

class LocationDetailsViewController: UIViewController, MKMapViewDelegate {
    
    var pin: Pin!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttomToolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMap()
    }
    
    fileprivate func configureMap() {
        
        mapView.delegate = self
        
        let pinCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: pinCoordinate, span: mapView.region.span)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pinCoordinate
        
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
        mapView.isUserInteractionEnabled = false
    }

}
