//
//  VisitedPhotosViewController.swift
//  My World Map
//
//  Created by Norah Al Ibrahim on 2/5/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import  CoreData

class VisitedPhotosViewController: UIViewController {
    
    @IBOutlet weak var visitedCollectionView: UICollectionView!
    @IBOutlet weak var visitedLocationMap: MKMapView!
    @IBOutlet weak var addPhoto: UIButton!
    
    var pin: Pin?
    var coreDataStack = CoreDataStack()
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var totalPages: Int? = nil
    var presentingAlert = false
    var selectedIndex: IndexPath!
    var editState: Bool!
    var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add edit button to the navigation bar
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButton
        
        //set mapview settings
        visitedLocationMap.delegate = self
        visitedLocationMap.isZoomEnabled = false
        visitedLocationMap.isScrollEnabled = false
        guard let pin = pin else {
            return
        }
        
        // show the pin on the map view
        let lat = Double(pin.latitude!)!
        let long = Double(pin.longitude!)!
        let locationCoordinate = CLLocationCoordinate2D(latitude: lat , longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        visitedLocationMap.removeAnnotations(visitedLocationMap.annotations)
        visitedLocationMap.addAnnotation(annotation)
        visitedLocationMap.setCenter(locationCoordinate, animated: true)
        
        //fetch photos saved on core data for the selected location
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
    
    @IBAction func addPhoto(_ sender: Any) {
        //display photo library to user
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
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
            addPhoto.isEnabled = false
        } else {
            editButton.title = "Edit"
            addPhoto.isEnabled = true
        }
        
    }
}

extension VisitedPhotosViewController: MKMapViewDelegate
{
    
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
}

extension VisitedPhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
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
        let cell = visitedCollectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photo = fetchedResultsController.object(at: indexPath)
        let photoViewCell = cell as! PhotoCollectionViewCell
        photoViewCell.imageUrl = photo.imageUrl!
        if let imageData = photo.image {
            photoViewCell.activityIndicator.stopAnimating()
            photoViewCell.imageView.image = UIImage(data: Data(referencing: imageData))
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
        else {
            selectedIndex = indexPath
            performSegue(withIdentifier:"showDetails", sender: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (visitedCollectionView.frame.size.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
}

extension VisitedPhotosViewController: NSFetchedResultsControllerDelegate {
    
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
        
        visitedCollectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.visitedCollectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.visitedCollectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.visitedCollectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}

extension VisitedPhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //save selected image to core data
        if let image =  info[UIImagePickerController.InfoKey.originalImage] as? UIImage  {
            do {
                try coreDataStack.addPhoto(pin: pin!, image: image)
            } catch{
                showInfo(withMessage: "Picture can't be saved")
            }
        } else{
            showInfo(withMessage: "Picture can't be selected")
        }
        dismiss(animated: true, completion: nil)
        visitedCollectionView.reloadData()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //close the image picker controller
        dismiss(animated: true, completion: nil)
    }
    
    
}
