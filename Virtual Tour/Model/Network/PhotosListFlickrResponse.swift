//
//  PhotosListFlickrResponse.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
//MARK: Implementation of response for photos search request
struct PhotosListFlickrResponse: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    // List of details of photos struct
    let photo: [FlickrPhotoDetails]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perpage
        case total
        case photo
    }
}
