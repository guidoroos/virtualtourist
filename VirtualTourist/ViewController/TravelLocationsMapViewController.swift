//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Guido Roos on 16/08/2023.
//

import Foundation
import MapKit
import UIKit

class TravelLocationsMapViewController: BaseViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    let dataController = DataController.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupPersistedPins()

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPin(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }

    func setupPersistedPins()  {
        Task {
            guard let pins = try? await dataController.read(
                DatabasePin.self,
                predicate: nil,
                sortDescriptors: nil
            ) else {
                return
            }
            
            for pin in pins {
                let coordinate = CLLocationCoordinate2D(
                    latitude: pin.latitude as! CLLocationDegrees,
                    longitude: pin.longitude as! CLLocationDegrees)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
            }
        }
    }

    func presentModalViewController(photos: [ImageInfo], coordinate: CLLocationCoordinate2D) {
        guard let modalViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as? PhotoAlbumViewController else {
            print("Something wrong in storyboard")
            return
        }

        if let sheet = modalViewController.sheetPresentationController {
            sheet.detents = [
                .medium(),
                .large()
            ]

            sheet.prefersGrabberVisible = true
        }

        modalViewController.data = photos
        modalViewController.coordinate = coordinate

        present(modalViewController, animated: true, completion: nil)
    }

    func getPhotosForNewLocation(coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                spinner?.startAnimating()

                let photosResponse = try await FlickrApi.getLocationPhotos(
                    lat: coordinate.latitude,
                    long: coordinate.longitude
                )
                let photos = photosResponse.photos.photo

                if let pin = try? await dataController.create(DatabasePin.self) {
                    pin.latitude = NSDecimalNumber(value: coordinate.latitude)
                    pin.longitude = NSDecimalNumber(value: coordinate.longitude)
                    
                 
                    Task.init {
                        for photo in photos {
                            let data = try? await FlickrApi.getImageForPhotoInfo(photoURL: photo.photoUrl)?.pngData()
                            
                            if let dbPhoto = try? await dataController.create(DatabasePhoto.self) {
                                dbPhoto.pin = pin
                                dbPhoto.data = data
                                dbPhoto.title = photo.title
                            }
                        }
                    }
                    
                    spinner?.stopAnimating()
                    presentModalViewController(photos: photos, coordinate: coordinate)
                }
            } catch {
                spinner?.stopAnimating()

                let apiError = (error as? APIError)
                let description = apiError?.description ?? NSLocalizedString("unkown_error", comment: "")

                let alert = TwoButtonAlert.create(
                    title: NSLocalizedString("get_locations_failure_title", comment: ""),
                    message: description,
                    actionLabel: NSLocalizedString("retry_button_text", comment: ""),
                    action: { [weak self] in
                        self?.getPhotosForNewLocation(
                            coordinate: coordinate
                        )
                    }
                )

                present(alert, animated: true)

                print(String(describing: apiError) + ": " + description)
            }
        }
    }

    func getPhotosForExistingLocation(coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                self.spinner?.startAnimating()

                let lat = NSDecimalNumber(value: coordinate.latitude)
                let long = NSDecimalNumber(value: coordinate.longitude)

                guard let databasePin = try? await dataController.read(
                    DatabasePin.self,
                    predicate: NSPredicate(format: "latitude == %@ AND longitude == %@", lat, long),
                    sortDescriptors: nil
                ).first else {
                    getPhotosForNewLocation(coordinate: coordinate)
                    return
                }

                guard let photos = try? await dataController.read(
                    DatabasePhoto.self,
                    predicate: NSPredicate(format: "pin == %@", databasePin),
                    sortDescriptors: nil
                ) else {
                    getPhotosForNewLocation(coordinate: coordinate)
                    return
                }

                self.spinner?.stopAnimating()
                presentModalViewController(photos: photos, coordinate: coordinate)
            }
        }
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView

        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.markerTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }

        // Check if the annotation is an existing marker
        if let existingAnnotation = mapView.annotations.first(where: { $0 === annotation }) {
            let coordinate = existingAnnotation.coordinate

            getPhotosForExistingLocation(coordinate: coordinate)
        }
    }

    @objc func addPin(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)

            getPhotosForNewLocation(coordinate: coordinate)
        }
    }
}
