//
//  Photo.swift
//  VirtualTourist
//
//  Created by Guido Roos on 18/08/2023.
//

protocol ImageInfo {
    var photoUrl: String { get }
    var imageId: String { get }
}

struct Photo: Codable, ImageInfo {
    var id: String
    var owner: String
    var secret: String
    var server: String
    var farm: Int
    var title: String
    var ispublic: Int
    var isfriend: Int
    var isfamily: Int

    var imageId: String {
        return id
    }

    var photoUrl: String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
}

extension DatabasePhoto: ImageInfo {
    var photoUrl: String {
        return url ?? ""
    }
    var imageId: String {
        return id ?? ""
    }
}
