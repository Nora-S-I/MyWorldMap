//
//  VisitedViewController.swift
//  My World Map
//
//  Created by Norah Al Ibrahim on 2/5/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit

class VisitedViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var pinAnnotation: MKPointAnnotation? = nil
    let coreDataStack = CoreDataStack()
    var editingState: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        editingState = false
        
        //display previous pins
        var previousPins: [Pin]?
        do {
            try  previousPins = coreDataStack.fetchAllPins(isVisited: true, entityName: Pin.name)
        } catch {
            showInfo(withTitle: "Error", withMessage: "Error while fetching Pin locations: \(error)")
        }
        if let pins = previousPins {
            for pin in pins where pin.latitude != nil && pin.longitude != nil {
                let annotation = MKPointAnnotation()
                let latitude = Double(pin.latitude!)!
                let longitude = Double(pin.longitude!)!
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                mapView.addAnnotation(annotation)
            }
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
        
    }
    
    @IBAction func edit(_ sender: Any) {
        //change editing state
        editingState = !editingState
        
        if editingState {
            configureEditButton(editState: editingState, buttonTitle: "Done")
        }else {
            configureEditButton(editState: editingState, buttonTitle: "Edit")
        }
    }
    
    @IBAction func addPinLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        if !editingState{
            let location = sender.location(in: mapView)
            let locationCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
           
            switch sender.state {
            case .began:
                pinAnnotation = MKPointAnnotation()
                pinAnnotation!.coordinate = locationCoordinate
                mapView.addAnnotation(pinAnnotation!)
                break
            case .changed:
                pinAnnotation!.coordinate = locationCoordinate
                break
            case .ended:
                _ = Pin(latitude: String(pinAnnotation!.coordinate.latitude), longitude: String(pinAnnotation!.coordinate.longitude), isVisited: true,
                        context: coreDataStack.managedObjectContext)
                coreDataStack.saveContext()
                break
            case .possible, .cancelled, .failed:
                break
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VisitedPhotosViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! VisitedPhotosViewController
            controller.pin = pin
            controller.coreDataStack = coreDataStack
        }
    }
    
    func configureEditButton (editState: Bool, buttonTitle: String){
        let tabBarControllerItems = self.tabBarController?.tabBar.items
        editButton.title = buttonTitle
        tabBarControllerItems?[0].isEnabled = !editState
        tabBarControllerItems?[1].isEnabled = !editState
    }
}

// Map View delegattion
extension VisitedViewController {
    
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
        //delete pin
        if editingState {
            
            do{
                try coreDataStack.deletePin(latitude:String(annotation.coordinate.latitude) , longitude: String(annotation.coordinate.longitude))
                mapView.removeAnnotation(annotation)
            }catch{
                showInfo(withTitle: "Error", withMessage: "Couldn't delete the pin")
            }
        }
            //performe segue
        else {
            mapView.deselectAnnotation(annotation, animated: true)
            let latitude = String(annotation.coordinate.latitude)
            let longitude = String(annotation.coordinate.longitude)
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
            var pin: Pin?
            do {
                try pin = coreDataStack.fetchPin(predicate, entityName: Pin.name)
                performSegue(withIdentifier: "viewVisited", sender: pin)
            } catch {
                showInfo(withTitle: "Error", withMessage: "Error while fetching location: \(error)")
            }
        }
    }
    
}
