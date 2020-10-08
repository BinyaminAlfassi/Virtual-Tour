//
//  LocationDetailsViewController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import UIKit
import MapKit
import CoreData

class LocationDetailsViewController: UIViewController, MKMapViewDelegate {
    
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttomToolbar: UIToolbar!
    
    let photoCollectionViewCellId = "PhotoCollectionViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        configureCollectionView()
        configureMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
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
    
    func configureCollectionView() {
        collectionView.delegate = self
        
    }
    
    func getAllPhotosFromFlickr() {
        FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude) { (photosDataList, error) in
            if let error = error {
                print(error)
            } else {
                for photoData in photosDataList {
                    self.addPhotoToDB(photoData: photoData)
                }
            }
        }
    }
    
    func addPhotoToDB(photoData: Data) {
        let newPhoto = Photo(context: DataController.shared.backgroundContext)
        newPhoto.photo = photoData
        newPhoto.pin = self.pin
        DispatchQueue.main.async {
            do {
                try DataController.shared.backgroundContext.save()
            } catch {
                print("")
            }
        }
    }
    
    func fetchPhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photo", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.backgroundContext, sectionNameKeyPath: nil, cacheName: "photosOf\(String(pin.latitude))\(String(pin.longitude))")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                getAllPhotosFromFlickr()
            }
        } catch {
            
        }
        collectionView.reloadData()
    }
}

extension LocationDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCollectionViewCellId, for: indexPath) as! PhotoCollectionViewCell
        let cellPhoto = fetchedResultsController.object(at: indexPath)
        
        if let photo = cellPhoto.photo {
            cell.imageView.image = UIImage(data: photo)
        }
        
        return cell
    }
    
    
}

extension LocationDetailsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }
}
