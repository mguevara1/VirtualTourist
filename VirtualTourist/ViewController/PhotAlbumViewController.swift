//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: BaseViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // MARK: Outlets and properties

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    let annotation = MKPointAnnotation()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var page: Int = 0
    var cellsPerRow = 0
    var photos: [Photo] = []
    var flickrPhotos: [FlickrPhoto] = []
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        self.photoCollection.delegate = self
        
        setupFetchedResultsController()
        
        flickrPhotos = fetchedResultsController.fetchedObjects ?? []
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            getPhotos()
        } else {
            photoCollection.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showActivityIndicator()
        showSelectedPin()
        getPhotos()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: IBActions
    
    @IBAction func loadNewCollection(_ sender: UIBarButtonItem) {
        newCollectionButton.isEnabled = false
        clearPhotos()
        photos = []
        flickrPhotos = []
        getPhotos()
        photoCollection.reloadData()
    }
    
    //MARK: functions
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<FlickrPhoto> = FlickrPhoto.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "image", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be perfomed: \(error.localizedDescription)")
        }
    }
    
    func getImageURL() {
        for photo in photos {
            let flickrPhoto = FlickrPhoto(context: dataController.viewContext)
            flickrPhoto.imageUrl = photo.url_sq
            flickrPhoto.pin = pin
            flickrPhotos.append(flickrPhoto)
            do {
                try dataController.viewContext.save()
            } catch {
                debugPrint("Error retrieving image url")
            }
        }
        DispatchQueue.main.async {
            self.photoCollection.reloadData()
        }
    }
    
    func getPhotos() {
        showActivityIndicator()
        PhotoSearch.searchPhotos(lat: latitude, lon: longitude, page: page, completion: { (photos, error) in
            if (photos != nil) {
                if photos?.pages == 0 {
                    self.noPhotosLabel.isHidden = false
                    self.newCollectionButton.isEnabled = false
                    self.hideActivityIndicator()
                } else {
                    self.photos = (photos?.photo)!
                    let randomPage = Int.random(in: 1...photos!.pages)
                    self.page = randomPage
                    print(self.page)
                    self.getImageURL()
                    self.photoCollection.reloadData()
                    self.hideActivityIndicator()
                }
            } else {
                self.showAlert(message: "Error retrieving photos", title: "Error")
                self.newCollectionButton.isEnabled = true
                self.hideActivityIndicator()
            }
        })
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
    
    func clearPhotos() {
        for flickrPhoto in flickrPhotos {
            dataController.viewContext.delete(flickrPhoto)
            do {
                try self.dataController.viewContext.save()
            } catch {
                self.showAlert(message: "Error clearing the collection", title: "Error")
            }
        }
    }
    
    func showSelectedPin() {
        mapView.removeAnnotations(mapView.annotations)
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        mapView.addAnnotation(annotation)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        newCollectionButton.isEnabled = false
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        let cellImage = flickrPhotos[indexPath.row]
        
        if cellImage.image != nil {
            cell.photoImageView.image = UIImage(data: cellImage.image!)
            newCollectionButton.isEnabled = true
        } else {
           cell.photoImageView.image = UIImage(named: "ImagePlaceholder")
            
            if cellImage.imageUrl != nil {
                let url = URL(string: cellImage.imageUrl ?? "")
                PhotoSearch.downloadPhoto(url: url!) { (data, error) in
                    if (data != nil) {
                        DispatchQueue.main.async {
                            cellImage.image = data
                            cellImage.pin = self.pin
                            do {
                                try self.dataController.viewContext.save()
                            } catch {
                                debugPrint("Error saving photos")
                            }
                            DispatchQueue.main.async {
                                cell.photoImageView?.image = UIImage(data: data!)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showAlert(message: "Error downloading photos", title: "Error")
                        }
                        
                    }
                    DispatchQueue.main.async {
                        self.newCollectionButton.isEnabled = true
                    }
                    
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: "Delete", message: "Are you suere you want to delete this photo?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction) in
            let flickrPhoto = self.flickrPhotos[indexPath.row]
            self.dataController.viewContext.delete(flickrPhoto)
            self.flickrPhotos.remove(at: indexPath.row)
        do {
            try self.dataController.viewContext.save()
        } catch {
            self.showAlert(message: "Error deleting photo", title: "Error")
        }
            self.photoCollection.reloadData()
        }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
                alertVC.dismiss(animated: true, completion: nil)
            }))
            self.present(alertVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
         let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + (flowLayout.minimumInteritemSpacing * CGFloat(cellsPerRow - 1))
         let size = Int((photoCollection.bounds.width - totalSpace) / CGFloat(cellsPerRow))
         return CGSize(width: size, height: size)
    }
    
    override func viewWillLayoutSubviews() {
        guard let flowLayout = photoCollection.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        cellsPerRow = UIDevice.current.orientation == .portrait ? 3 : 5
        
        flowLayout.invalidateLayout()
    }
    
}

