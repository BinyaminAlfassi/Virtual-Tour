//
//  FlickrClient.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
import MapKit


class FlickrClient {
    static let apiKey = ""
    
    static let searchRadiusSize = "15"
    static let prePage = "60"
    static var page = "1"
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/"
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
//        static let radiusParamString = "&radius="
        static let perPageParamString = "&per_page="
//        static let pageParamString = "&page="
        static let latitudeParamString = "&lat="
        static let longitudeParamString = "&lon="
        
        
        case  searchPhotos (perPage: String, latitude: Double, longitude: Double)
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
        var stringValue: String {
            switch self {
            case .searchPhotos (let perPage,let latitude, let longitude):
                let coordinates = Endpoints.latitudeParamString + String(latitude) + Endpoints.longitudeParamString + String(longitude)
//                return Endpoints.base + Endpoints.apiKeyParam + "&method=flickr.photos.search" + "&format=json" + Endpoints.radiusParamString + radius + Endpoints.perPageParamString + perPage + Endpoints.pageParamString + page + coordinates
                return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyParam + coordinates + Endpoints.perPageParamString + perPage + "&format=json&nojsoncallback=1"
            }
        }
    }
    
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                  completion(nil, error)
                }
                return
            }
            let newData = data
            let decoder = JSONDecoder()
            print(String(data: newData, encoding: .utf8)!)
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    func getPhotos(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping ([Photo], Error?) -> Void) {
        
    }
}
