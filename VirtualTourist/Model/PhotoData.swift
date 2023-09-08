//
//  PhotoQueryData.swift
//  VirtualTourist
//
//  Created by Guido Roos on 18/08/2023.
//

struct PhotoData: Codable {
    var page    : Int
    var pages   : Int
    var perpage : Int
    var total   : Int
    var photo   : [Photo] = []
}

