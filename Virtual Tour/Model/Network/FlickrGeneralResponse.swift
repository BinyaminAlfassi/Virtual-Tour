//
//  FlickrGeneralResponse.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation

//MARK: Implementing a general response of Flickr for photo search request indicating an error
struct FlickrGeneralResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension FlickrGeneralResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
