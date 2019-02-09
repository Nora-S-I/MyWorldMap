//
//  ToVisitViewController.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit

class ToVisitViewController: UIViewController {
    
    @IBOutlet weak var touristMapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var pinAnnotation: MKPointAnnotation? = nil
    let coreDataStack = CoreDataStack()
    var editingState: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        touristMapView.delegate = self
        editingState = false
        
        //display previously saved pins on the map
        var previousPins: [Pin]?
        do {
            try  previousPins = coreDataStack.fetchAllPins(isVisited: false, entityName: Pin.name)
        } catch {
            showInfo(withTitle: "Error", withMessage: "Error while fetching Pin locations: \(error)")
        }
        if let pins = previousPins {
            for pin in pins where pin.latitude != nil && pin.longitude != nil {
                let annotation = MKPointAnnotation()
                let latitude = Double(pin.latitude!)!
                let longitude = Double(pin.longitude!)!
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                touristMapView.addAnnotation(annotation)
            }
            touristMapView.showAnnotations(touristMapView.annotations, animated: true)
        }
    }
    
    @IBAction func edit(_ sender: Any) {
        //change editing state
        editingState = !editingState
        //when start editing, change to edit mode
        if editingState {
            configureEditButton(editState: editingState, buttonTitle: "Done")
        }
            //when finish editing, get back orginal mode
        else {
            configureEditButton(editState: editingState, buttonTitle: "Edit")
        }
        
    }
    @IBAction func addPinLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        //allow user to add pin only if the user not on edit mode
        if !editingState{
            let location = sender.location(in: touristMapView)
            let locationCoordinate = touristMapView.convert(location, toCoordinateFrom: touristMapView)
            switch sender.state {
            case .began:
                pinAnnotation = MKPointAnnotation()
                pinAnnotation!.coordinate = locationCoordinate
                touristMapView.addAnnotation(pinAnnotation!)
                break
            case .changed:
                pinAnnotation!.coordinate = locationCoordinate
                break
            case .ended:
                _ = Pin(latitude: String(pinAnnotation!.coordinate.latitude), longitude: String(pinAnnotation!.coordinate.longitude), isVisited: false,
                        context: coreDataStack.managedObjectContext)
                coreDataStack.saveContext()
                break
            case .possible, .cancelled, .failed:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ToVisitPhotosViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! ToVisitPhotosViewController
            controller.pin = pin
            controller.coreDataStack = coreDataStack
        }
    }
    
    //function to configure the view controller interface when the user start and done editing
    func configureEditButton (editState: Bool, buttonTitle: String){
        let tabBarControllerItems = self.tabBarController?.tabBar.items
        editButton.title = buttonTitle
        tabBarControllerItems?[0].isEnabled = !editState
        tabBarControllerItems?[1].isEnabled = !editState
    }
}

// Map View delegattion
extension ToVisitViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            self.showInfo(withMessage: "No link defined.")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        //if user on edit mode, delete pin
        if editingState {
            
            do{
                try coreDataStack.deletePin(latitude:String(annotation.coordinate.latitude) , longitude: String(annotation.coordinate.longitude))
                mapView.removeAnnotation(annotation)
            }catch{
                showInfo(withTitle: "Error", withMessage: "Couldn't delete the pin")
            }
        }
            //if user is not editing, performe segue
        else {
            mapView.deselectAnnotation(annotation, animated: true)
            let latitude = String(annotation.coordinate.latitude)
            let longitude = String(annotation.coordinate.longitude)
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
            var pin: Pin?
            do {
                try pin = coreDataStack.fetchPin(predicate, entityName: Pin.name)
                performSegue(withIdentifier: "viewToVisit", sender: pin)
            } catch {
                showInfo(withTitle: "Error", withMessage: "Error while fetching location: \(error)")
            }
        }
    }
    
}
