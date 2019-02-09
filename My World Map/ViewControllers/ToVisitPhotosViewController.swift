//
//  ToVisitPhotosViewController.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ToVisitPhotosViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var pinLocationMapView: MKMapView!
    @IBOutlet weak var photoColloectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var totalPages: Int? = nil
    var presentingAlert = false
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var coreDataStack = CoreDataStack()
    var editState: Bool!
    var selectedIndex: IndexPath!
    var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add edit button to the navigation bar
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButton
        
        //set mapview settings
        pinLocationMapView.delegate = self
        pinLocationMapView.isZoomEnabled = false
        pinLocationMapView.isScrollEnabled = false
        guard let pin = pin else {
            return
        }
        
        // show the pin on the map view
        let lat = Double(pin.latitude!)!
        let long = Double(pin.longitude!)!
        let locationCoordinate = CLLocationCoordinate2D(latitude: lat , longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        pinLocationMapView.removeAnnotations(pinLocationMapView.annotations)
        pinLocationMapView.addAnnotation(annotation)
        pinLocationMapView.setCenter(locationCoordinate, animated: true)
        
        //fetch saved photos for the selected location
        let fetchRequest = NSFetchRequest<Photo>(entityName: Photo.name)
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            showInfo(withTitle: "Error", withMessage: "Error occure while fetching photos")
        }
        // pin selected has no saved photos in core data
        if let photos = pin.photos , photos.count == 0 {
            
            fetchPhotosFromFlickr(pin)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
        editState = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func newCollectionButton(_ sender: Any) {
        //delete photos from core data
        for photos in fetchedResultsController.fetchedObjects! {
            coreDataStack.managedObjectContext.delete(photos)
        }
        coreDataStack.saveContext()
        //fetch new photos prom flickr
        fetchPhotosFromFlickr(pin!)
    }
    
    func fetchPhotosFromFlickr(_ pin: Pin) {
        
        let latitude = Double(pin.latitude!)!
        let longitude = Double(pin.longitude!)!
        
        //fetch data from flickr
        FlickrClient.shared().searchBy(latitude: latitude, longitude: longitude, totalPages: totalPages) { (photosParsed, error) in
            
            if let photosParsed = photosParsed {
                self.totalPages = photosParsed.photos.pages
                let totalPhotos = photosParsed.photos.photo.count
                let photos = photosParsed.photos.photo
                //save fetched data from flickr to core data
                for photo in photos {
                    self.performUIUpdatesOnMain {
                        if let url = photo.url {
                            _ = Photo(title: photo.title, imageUrl: url, forPin: pin, context: self.coreDataStack.managedObjectContext)
                            self.coreDataStack.saveContext()
                        }
                    }
                }
                
                if totalPhotos == 0 {
                    self.showInfo(withTitle: "Notification", withMessage: "No photos found for this location")
                }
            } else if error != nil {
                self.showInfo(withTitle: "Error", withMessage: "Something went wrong, please try again")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotosViewerViewController {
            
            let controller = segue.destination as! PhotosViewerViewController
            controller.photoArray = fetchedResultsController.fetchedObjects!
            controller.selectedIndex = selectedIndex.row
            
        }
    }
    
    //function to configure view controller interface when user start and done editing
    @objc func editMode(){
        editState = !editState
        if editState{
            editButton.title = "Done"
            newCollection.isEnabled = false
        } else {
            editButton.title = "Edit"
            newCollection.isEnabled = true
        }
        
    }
}

//delegations extension
extension ToVisitPhotosViewController: NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = photoColloectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photo = fetchedResultsController.object(at: indexPath)
        let photoViewCell = cell as! PhotoCollectionViewCell
        photoViewCell.imageUrl = photo.imageUrl!
        //check if the photo already saved in the core data
        if let imageData = photo.image {
            photoViewCell.activityIndicator.stopAnimating()
            photoViewCell.imageView.image = UIImage(data: Data(referencing: imageData))
        } else {
            if let imageUrl = photo.imageUrl {
                photoViewCell.activityIndicator.startAnimating()
                //download the photo from flickr
                FlickrClient.shared().downloadImage(imageUrl: imageUrl) { (data, error) in
                    if let _ = error {
                        self.performUIUpdatesOnMain {
                            photoViewCell.activityIndicator.stopAnimating()
                            if !self.presentingAlert {
                                self.showInfo(withTitle: "Error", withMessage: "Error while fetching image for URL: \(imageUrl)", action: {
                                    self.presentingAlert = false
                                })
                            }
                            self.presentingAlert = true
                        }
                        return
                    } else if let data = data {
                        self.performUIUpdatesOnMain {
                            
                            if let currentCell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
                                if currentCell.imageUrl == imageUrl {
                                    currentCell.imageView.image = UIImage(data: data)
                                    photoViewCell.activityIndicator.stopAnimating()
                                }
                            }
                            photo.image = NSData(data: data)
                            DispatchQueue.global(qos: .background).async {
                                self.coreDataStack.saveContext()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //if user is editing, delete the selected photo
        if editState {
            let photoToDelete = fetchedResultsController.object(at: indexPath)
            coreDataStack.managedObjectContext.delete(photoToDelete)
            coreDataStack.saveContext()
        }
            //if user is not editing, performe segue
        else{
            selectedIndex = indexPath
            performSegue(withIdentifier:"showDetails", sender: nil)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        let photo = fetchedResultsController.object(at: forItemAt)
        if let imageUrl = photo.imageUrl {
            FlickrClient.shared().cancelDownload(imageUrl)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (photoColloectionView.frame.size.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        photoColloectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.photoColloectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoColloectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoColloectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}


