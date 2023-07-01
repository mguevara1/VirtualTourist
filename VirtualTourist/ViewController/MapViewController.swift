//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

import UIKit
import MapKit
import CoreData

class MapViewController: BaseViewController, MKMapViewDelegate {
    
    // MARK: Outlets and Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    var annotations = [MKPointAnnotation]()
    var annotation = MKPointAnnotation()
    var pins: [Pin] = []
    var dataController: DataController!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        mapView.addGestureRecognizer(gestureRecognizer)
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem!.title = "Edit"
        showActivityIndicator()
        pins = fetchPins()
        if pins.count > 0 {
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showActivityIndicator()
        mapView.deselectAnnotation(annotations as? MKAnnotation, animated: false)
        hideActivityIndicator()
    }
    
    func fetchPins() -> [Pin] {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            pins = result
            hideActivityIndicator()
        } catch {
            showAlert(message: "Error retrieving pins", title: "Error")
            hideActivityIndicator()
        }
        return pins
    }
    
    // MARK: Add pin on long press
    
    @objc func handleTap(gestureReconizer: UIGestureRecognizer) {
        if gestureReconizer.state == .began {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            print(pin.latitude)
            print(pin.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            print(annotation.coordinate)
            mapView.addAnnotation(annotation)
            do {
                try dataController.viewContext.save()
            } catch {
                showAlert(message: "There was an error saving the pin", title: "Sorry")
            }
            pins.append(pin)
            mapView.reloadInputViews()
            hideActivityIndicator()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { debugPrint("No MKPointAnnotaions"); return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.tintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if isEditing, let viewAnnotation = view.annotation {
            for pin in pins {
                if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                    dataController.viewContext.delete(pin)
                }
            }
            do {
                try dataController.viewContext.save()
            } catch {
                showAlert(message: "Error deleting pins", title: "Error")
            }
            mapView.removeAnnotation(viewAnnotation)
            return
        }
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        controller.latitude = view.annotation?.coordinate.latitude ?? 0.0
        controller.longitude = view.annotation?.coordinate.longitude ?? 0.0
        for pin in pins {
            if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                controller.pin = pin
            }
            
        }
        controller.dataController = dataController
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func setEditing(_ editing:Bool, animated:Bool) {
        super.setEditing(editing, animated: animated)
        if (self.isEditing) {
            toolBar.isHidden = false
            deletePinsLabel.isHidden = false
            self.editButtonItem.title = "Done"
        } else {
            toolBar.isHidden = true
            deletePinsLabel.isHidden = true
            self.editButtonItem.title = "Edit"
        }
    }
    
}

