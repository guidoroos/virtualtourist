//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Guido Roos on 16/08/2023.
//

import Foundation
import UIKit
import MapKit

class PhotoAlbumViewController: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var data: [ImageInfo] = []
    var onNewCollection: (() -> Void)!
    var coordinate: CLLocationCoordinate2D!
    @IBOutlet var collectionView: UICollectionView!

    let cellIdentifier = "CellIdentifier"

    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    private let itemsPerRow: CGFloat = 3
    private let minimumInteritemSpacing: CGFloat = 6.0
    private let minimumLineSpacing: CGFloat = 6.0 // updated spacing value

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        layout.minimumLineSpacing = minimumLineSpacing // updated spacing value
        layout.minimumInteritemSpacing = minimumInteritemSpacing
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        addBottomButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let spinner = spinner {
            spinner.color = .black
            view.bringSubviewToFront(spinner)
        }
    }

    func addBottomButton() {
        let button = UIButton(type: .system)
        button.setTitle("New Collection", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(button)
        
        button.backgroundColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)

        // Set button constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 40),
            button.heightAnchor.constraint(equalToConstant: 75)
        ])
    }

    @objc func buttonTapped() {
        let lat = self.coordinate.latitude
        let long = self.coordinate.longitude
        
        getPhotosForLocation(lat: lat, long: long)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        let photo = data[indexPath.row]
        cell.configure(with: photo)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        data.remove(at: indexPath.row)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width - (sectionInsets.left + sectionInsets.right + minimumInteritemSpacing * (itemsPerRow - 1))
        let cellWidth = availableWidth / itemsPerRow
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func getPhotosForLocation(lat: Double, long:Double) {
        Task {
            do {
                spinner?.startAnimating()
                
                let photosResponse = try await FlickrApi.getLocationPhotos(
                    lat: lat,
                    long: long
                )
                self.data = photosResponse.photos.photo
                self.collectionView.reloadData()
                
                spinner?.stopAnimating()
                
            } catch {
                spinner?.stopAnimating()
                
                let apiError = (error as? APIError)
                let description = apiError?.description ?? NSLocalizedString("unkown_error", comment: "")
                
                let alert = OneButtonAlert.create(
                    title: NSLocalizedString("get_locations_failure_title", comment: ""),
                    message: description
                )
                
                present(alert, animated: true)
                
                print(String(describing: apiError) + ": " + description)
            }
        }
    }
}
