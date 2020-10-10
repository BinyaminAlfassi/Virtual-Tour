//
//  FlickrPhoto.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
//MARK: Implementation of response to search photos
struct FlickrPhotoResponseWrap: Codable {
    // List of Photo details structs
    let photos: PhotosListFlickrResponse
    // Status
    let stat: String
}
