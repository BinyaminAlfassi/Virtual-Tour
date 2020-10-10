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
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let itemsPerRow: CGFloat = 4
    let collectionSectionInsets = UIEdgeInsets(top: 5.0,
    left: 5.0,
    bottom: 50.0,
    right: 5.0)
    
    let photoCollectionViewCellId = "PhotoCollectionViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        configureCollectionView()
        configureMap()
        setGestureRecognition()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        activityIndicatorStart(true)
        deleteAllImages()
        collectionView.reloadData()
        getAllPhotosFromFlickr()
        collectionView.reloadData()
        activityIndicatorStart(false)
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
        FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude) { (photoData, error) in
            if let error = error {
                self.showAlertMessage(message: "\(error)")
            } else {
                self.addPhotoToDB(photoData: photoData!)
            }
        } ifNoPhotosDo: {self.showMessageNoImages()}
    }
    
    func addPhotoToDB(photoData: Data) {
        let newPhoto = Photo(context: DataController.shared.viewContext)
        newPhoto.photo = photoData
        newPhoto.pin = self.pin
        DispatchQueue.main.async {
            do {
                try DataController.shared.viewContext.save()
            } catch {
                print("\(error)")
            }
        }
    }
    
    func fetchPhotos() {
        
        activityIndicatorStart(true)
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        //let sortDescriptor = NSSortDescriptor(key: "photo", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []//[sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "photosOf\(String(pin.latitude))\(String(pin.longitude))")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                getAllPhotosFromFlickr()
            }
        } catch {
            showAlertMessage(message: "\(error)")
        }
        
        activityIndicatorStart(false)
        
        collectionView.reloadData()
    }
    
    func deleteAllImages() {
        if let photosToDelete = self.fetchedResultsController.fetchedObjects {
            for photo in photosToDelete.reversed() {
                deletePhoto(photo: photo)
            }
        }
    }
    
    func deletePhoto(photo: Photo) {
        DataController.shared.viewContext.delete(photo)
        do {
            try DataController.shared.viewContext.save()
        } catch {
            print(error)
        }
    }
}

extension LocationDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if fetchedResultsController == nil {return 1}
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fetchedResultsController == nil {return 0}
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

extension LocationDetailsViewController: UIGestureRecognizerDelegate {
    
    func setGestureRecognition() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        collectionView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func longTap(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.ended:
            let path = gestureRecognizer.location(in: self.collectionView)
            if let indexPath = self.collectionView.indexPathForItem(at: path) {
                let photo = fetchedResultsController.object(at: indexPath)
                deletePhoto(photo: photo)
                collectionView.deleteItems(at: [indexPath])
            }
        default:
            break
        }
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
    
    @objc func longTap(gestureRecognized: UIGestureRecognizer) {
        switch gestureRecognized.state {
        case UIGestureRecognizer.State.ended:
            let path = gestureRecognized.location(in: self.collectionView)
            if let indexPath = self.collectionView.indexPathForItem(at: path) {
                let photo = fetchedResultsController.object(at: indexPath)
                deletePhoto(photo: photo)
                collectionView.reloadData()
            }
        default:
            break
        }
    }
}

extension LocationDetailsViewController {
    
    func showMessageNoImages() {
        showAlertMessage(message: "No images found for this location.")
    }
    
    func showAlertMessage(message: String) {
        let vc = UIAlertController(title: "Note", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    
    func activityIndicatorStart(_ start: Bool) {
        activityIndicator.isHidden = !start
        if start{
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

extension LocationDetailsViewController : UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let paddingSpace = collectionSectionInsets.left * itemsPerRow
    let availableWidth = UIScreen.main.bounds.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    
    let frameSize = CGSize(width: widthPerItem, height: widthPerItem)
    
    return frameSize
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return collectionSectionInsets
  }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}
