//
//  FlickrPhoto.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation

struct FlickrPhotoResponseWrap: Codable {
    let photos: PhotosListFlickrResponse
    let stat: String
}
