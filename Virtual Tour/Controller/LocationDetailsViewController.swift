//
//  LocationDetailsViewController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import UIKit
import MapKit
import CoreData
//MARK: Class representing view presenting photos of chosen location
class LocationDetailsViewController: UIViewController, MKMapViewDelegate {
    //MARK: Outlets & variables
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttomToolbar: UIToolbar!
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // Variables for the use of collection view layout
    let itemsPerRow: CGFloat = 4
    let collectionSectionInsets = UIEdgeInsets(top: 5.0,
    left: 5.0,
    bottom: 50.0,
    right: 5.0)
    
    let photoCollectionViewCellId = "PhotoCollectionViewCell"
    
    //MARK: Methods
    //MARK: ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting Collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        // Configurations
        configureCollectionView()
        configureMap()
        setGestureRecognition()
    }
    // Fetching photos from DB or Flickr after view load
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchPhotos()
    }
    // Nullify fetchedResultsController before view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    //MARK: Actions
    // This method handles with tapping on New-Collection button
    @IBAction func newCollectionTapped(_ sender: Any) {
        // Set to Downloading state
        downloadModeStart(true)
        // deleting current images from Pin
        deleteAllImages()
        //collectionView.reloadData()
        // Getting new photos from Flickr
        getAllPhotosFromFlickr()
        // Reloading view
        collectionView.reloadData()
        // Exiting Downloading state
        downloadModeStart(false)
    }
    // Configurations of map
    fileprivate func configureMap() {
        mapView.delegate = self
        // Creating region according to location of pin
        let pinCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: pinCoordinate, span: mapView.region.span)
        // Creating annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = pinCoordinate
        // Adding annotation to map
        mapView.addAnnotation(annotation)
        // Setting map region
        mapView.setRegion(region, animated: true)
        mapView.isUserInteractionEnabled = false
    }
    // As the name suggest :)
    func configureCollectionView() {
        collectionView.delegate = self
    }
    // Getting photos of Pin from Flickr
    func getAllPhotosFromFlickr() {
        // Gettinng the photos using client method
        FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude) { (photoData, error) in
            if let error = error {
                // Error occured
                self.showAlertMessage(message: "\(error)")
            } else {
                // Add Pic to DB and eventually (automatically) to view
                self.addPhotoToDB(photoData: photoData!)
            }
        } ifNoPhotosDo: {self.showMessageNoImages()} //--> If no images - Show message to user
    }
    // Add photo to DB
    func addPhotoToDB(photoData: Data) {
        // Creating a photo instance
        let newPhoto = Photo(context: DataController.shared.viewContext)
        // setting its variables
        newPhoto.photo = photoData
        newPhoto.pin = self.pin
        // Saving photo to DB
        DispatchQueue.main.async {
            do {
                try DataController.shared.viewContext.save()
            } catch {
                print("\(error)")
            }
        }
    }
    // Get all photos from DB or Flickr
    func fetchPhotos() {
        // Setting Downloading mode
        downloadModeStart(true)
        // Setting a  fetch request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        // TBD Sort descriptor
        //let sortDescriptor = NSSortDescriptor(key: "photo", ascending: false)
        // predicate - photos of current pin only!
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []//[sortDescriptor]
        // Initializing FetchedResulsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "photosOf\(String(pin.latitude))\(String(pin.longitude))")
        fetchedResultsController.delegate = self
        // Fetching Photos of current pin
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                // No Photos found -> Getting photos from Flickr
                getAllPhotosFromFlickr()
            }
        } catch {
            // Error occured
            showAlertMessage(message: "\(error)")
        }
        // Reloading data
        collectionView.reloadData()
        // Exiting Download state
        downloadModeStart(false)
    }
    // Delete all images from  DB
    func deleteAllImages() {
        if let photosToDelete = self.fetchedResultsController.fetchedObjects {
            // Going over all photos of current pin and deletes them
            for photo in photosToDelete.reversed() {
                deletePhoto(photo: photo)
            }
        }
    }
    // Delete pin from DB and eventually (automatically) from view
    func deletePhoto(photo: Photo) {
        // deleting photo from context
        DataController.shared.viewContext.delete(photo)
        do {
            // saving changes
            try DataController.shared.viewContext.save()
        } catch {
            print(error)
        }
    }
}
//MARK: Extention providing functionality of collection view
extension LocationDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    // Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if fetchedResultsController == nil {return 1}
        return fetchedResultsController.sections?.count ?? 1
    }
    // number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fetchedResultsController == nil {return 0}
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    // Each cell in collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // getting the corrent cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCollectionViewCellId, for: indexPath) as! PhotoCollectionViewCell
        // getting coorect photo from DB corresponding to cell
        let cellPhoto = fetchedResultsController.object(at: indexPath)
        // Setting cell's image to be photo from DB
        if let photo = cellPhoto.photo {
            cell.imageView.image = UIImage(data: photo)
        }
        
        return cell
    }
}
//MARK: Extention providing functionality of long tapping gesture
extension LocationDetailsViewController: UIGestureRecognizerDelegate {
    // Configure gesture recognizer
    func setGestureRecognition() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        collectionView.addGestureRecognizer(gestureRecognizer)
    }
    // Hanles long tapp on an image in collection view and deletes the image
    @objc func longTap(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.ended:
            // getting the path of in collection view
            let path = gestureRecognizer.location(in: self.collectionView)
            // getting index
            if let indexPath = self.collectionView.indexPathForItem(at: path) {
                // getting the photo from DB
                let photo = fetchedResultsController.object(at: indexPath)
                // Deleting the photo
                deletePhoto(photo: photo)
                // delete from Collection View
                collectionView.deleteItems(at: [indexPath])
            }
        default:
            break
        }
    }
}
//MARK: Automatic update of the collectionView according to DB
extension LocationDetailsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            // Inseart new photo
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            // delete photo
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            // updating photo -> currently not in use
            collectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }
}


//MARK: Utilities
extension LocationDetailsViewController {
    // Shows message to user indicating there are no images for this location
    func showMessageNoImages() {
        showAlertMessage(message: "No images found for this location.")
    }
    // Show alert messages to the screen
    func showAlertMessage(message: String) {
        let vc = UIAlertController(title: "Note", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    // Starting/Exiting Download mode
    func downloadModeStart(_ start: Bool) {
        activityIndicator.isHidden = !start
        newCollectionButton.isEnabled = !start
        if start{
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}


//MARK: Layout
extension LocationDetailsViewController : UICollectionViewDelegateFlowLayout {
  // Calculation of framce size
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    // Calculatinng padding space
    let paddingSpace = collectionSectionInsets.left * itemsPerRow
    // Calculating total width for images
    let availableWidth = UIScreen.main.bounds.width - paddingSpace
    // Calculating width of each item
    let widthPerItem = availableWidth / itemsPerRow
    // Calculating frame size
    let frameSize = CGSize(width: widthPerItem, height: widthPerItem)
    
    return frameSize
  }
  // frame section insets
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return collectionSectionInsets
  }
    // minimum spacing for each section
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
  // minimum line spacing for each section
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}
