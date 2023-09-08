//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Guido Roos on 18/08/2023.
//

struct PhotosResponse: Codable {
    var photos : PhotoData
    var stat   : String? = nil
}
