//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var touristMapView: MKMapView!
    
    var pinAnnotation: MKPointAnnotation? = nil
    let coreDataStack = CoreDataStack()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegate
        touristMapView.delegate = self
        
        //display previous pins
        var previousPins: [Pin]?
        do {
            try  previousPins = coreDataStack.fetchAllPins(entityName: Pin.name)
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
    
    @IBAction func addPinLongPressGesture(_ sender: UILongPressGestureRecognizer) {
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
            _ = Pin(latitude: String(pinAnnotation!.coordinate.latitude), longitude: String(pinAnnotation!.coordinate.longitude), isVisited: true,
                context: coreDataStack.managedObjectContext)
            coreDataStack.saveContext()
            break
        case .possible, .cancelled, .failed:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotosViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! PhotosViewController
            controller.pin = pin
            controller.coreDataStack = coreDataStack
        }
    }
}

// Map View delegattion
extension MapViewController {
    
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

