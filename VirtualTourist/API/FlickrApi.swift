//
//  FlickrApi.swift
//  VirtualTourist
//
//  Created by Guido Roos on 16/08/2023.
//

import UIKit

class FlickrApi: ApiClient {
    static let formatting = "&format=json&nojsoncallback=1"

    enum Endpoint {
        case photoSearch(lat: Double, long: Double, page:Int)

        var stringValue: String {
            switch self {
            case let .photoSearch(lat, long, page):
        
                return "\(baseURL)?method=flickr.photos.search&api_key=\(ApiClient.apiKey)&lat=\(lat)&lon=\(long)\(formatting)&page=\(page)"
            }
        }
    }
    
    
    class func getLocationPhotos(lat: Double, long: Double, page: Int = 1) async throws -> PhotosResponse {
        return try await taskForGetRequest(url: getUrl(urlString: Endpoint.photoSearch(
            lat: lat,
            long: long,
            page: page
        ).stringValue)
        )
    }


    class func getImageForPhotoInfo(photoURL: String) async throws -> UIImage? {
        let (imageData, _) = try await URLSession.shared.data(from: getUrl(urlString: photoURL))

        return UIImage(data: imageData)
    }
}
