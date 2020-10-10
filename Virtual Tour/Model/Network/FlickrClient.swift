//
//  FlickrClient.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
import MapKit

//MARK: This class implements Client for Flickr operations
class FlickrClient {
    //MARK: variables & enums
    // API key
    static let apiKey = "0dccd2bb7906b155c6945aac98d58d12"
    // Defining Endpoings URLs
    enum Endpoints {
        // Base string for Flickr API
        static let base = "https://api.flickr.com/services/rest/"
        // API Key parameter string
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        // pre-page parameter string
        static let perPageParamString = "&per_page="
        // latitude parameter string
        static let latitudeParamString = "&lat="
        // longitude parameter string
        static let longitudeParamString = "&lon="
        
        // Search Photo endpoint
        case  searchPhotos (perPage: String, latitude: Double, longitude: Double)
        // returning a URL of the endpoint
        var url: URL {
            return URL(string: stringValue)!
        }
        // Defining string vlues
        var stringValue: String {
            switch self {
            case .searchPhotos (let perPage,let latitude, let longitude):
                let coordinates = Endpoints.latitudeParamString + String(latitude) + Endpoints.longitudeParamString + String(longitude)
                return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyParam + coordinates + Endpoints.perPageParamString + perPage + "&format=json&nojsoncallback=1"
            }
        }
    }
    
    //MARK: Methods
    // Generic GET Request method
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        // Defining the task request with URL
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print("Got to taskForGetRequest task")
            // Making sure data was revieved
            guard let data = data else {
                // Calling completion method with an error if data was not recieved
                DispatchQueue.main.async {
                  completion(nil, error)
                }
                return
            }
            let newData = data
            // Setting JSON decoder
            let decoder = JSONDecoder()
            print(String(data: newData, encoding: .utf8)!)
            do {
                // decoding response
                let responseObject = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    // Calling completion method with the response object
                    completion(responseObject, nil)
                }
            } catch {
                // In case of data could not be decoded properly
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        // Initiating the GET request task
        task.resume()
    }
    
    // This method get details of all photos for specific location (latitude and longitude)
    class func getPhotos(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (Data?, Error?) -> Void, ifNoPhotosDo: ((() -> Void))?) {
        // Setting url
        let url = Endpoints.searchPhotos(perPage: "30", latitude: latitude, longitude: longitude).url
        print(url)
        // Sending GET request
        taskForGetRequest(url: url, responseType: FlickrPhotoResponseWrap.self) { (response, error) in
            // Verifying resoinse has been recieved successfuly
            if let response = response {
                // Getting the list of photos details
                let photosList = response.photos.photo
                // Checking if the list is empty
                if photosList.count == 0 {
                    // Then call completion method 'ifNoPhotosDo'
                    if let ifNoPhotosDo = ifNoPhotosDo {
                        ifNoPhotosDo()
                        return
                    }
                }
                // Iterating every photo and getting its data from Flickr
                for photo in photosList {
                    // Sending GET request to retrieve photo's data
                    getImageData(url: photo.url) { (data, error) in
                        // making sure data was recieved
                        if let data = data {
                            // Call completion method with the data
                            completion(data, nil)
                        } else {
                            // Call completion method with an error
                            completion(nil, error)
                        }
                    }
                }
            } else {
                // Response was not recieved
                completion(nil, error)
            }
        }
    }
    
    // This method retriece specific photo's data from Flickr
    class func getImageData(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        print(url)
        // sending GET request with URL
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            // Verifiying data was recieved
            guard let data = data else {
                // Error occured
                completion(nil, error)
                return
            }
            // Cakking completion method with data
            completion(data, nil)
        }
        // Initiating the GET Request task
        task.resume()
    }
}
