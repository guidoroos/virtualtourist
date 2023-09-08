import UIKit

class PhotoCell: UICollectionViewCell {
    
    // Declare your UI elements as properties of the cell
    var photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    // Add any other UI elements you need
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Call setupUI() to configure the UI elements and constraints
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Add the UI elements to the cell's contentView
        contentView.addSubview(photoImageView)
        
        // Apply constraints to position and layout the UI elements
        
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(with photo: ImageInfo) {
        photoImageView.image = UIImage(named: "placeholder")
        
        if photo is Photo {
            loadImage(photo: photo)
        } else if photo is DatabasePhoto {
            
            let dbPhoto = photo as! DatabasePhoto
            if let data = dbPhoto.data {
                photoImageView.image = UIImage(data: data)
            } else {
                photoImageView.isHidden = true
            }
        }
    }
    
    func loadImage (photo: ImageInfo) {
        Task {
            do {
                if let image = try await FlickrApi.getImageForPhotoInfo(photoURL: photo.photoUrl) {
                        photoImageView.image = image
                    } else {
                        photoImageView.isHidden = true
                    }
               
            } catch {
                photoImageView.isHidden = true
            }
        }
                
    }
}
