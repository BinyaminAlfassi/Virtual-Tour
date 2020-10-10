//
//  FlickrPhotoDetails.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
//MARK: Implementation of details of a photo in Flickr in order to construct the URL of a photo data
struct FlickrPhotoDetails: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case ispublic
        case isfriend
        case isfamily
    }
    // Constructing the URL of photo's data
    var url: URL {return URL(string: "https://live.staticflickr.com/\(server)/\(id)_\(secret)_q.jpg")!}
}
