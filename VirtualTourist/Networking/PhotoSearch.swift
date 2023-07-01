//
//  PhotoSearch.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

import Foundation

class PhotoSearch {
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        static let photoSearch = "?method=flickr.photos.search"
        static let apiKey = "9d5de61d139d72ddd7040d9e1a6e66b1"
        
        case getPhotos(Double, Double, Int)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let lat, let lon, let page):
                return Endpoints.base + Endpoints.photoSearch + "&extras=url_sq" + "&api_key=\(Endpoints.apiKey)" + "&lat=\(lat)" + "&lon=\(lon)" + "&per_page=30" + "&page=\(page)" + "&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func searchPhotos(lat: Double, lon: Double, page: Int, completion: @escaping (Photos?, Error?) -> Void) {
        var request = URLRequest(url: Endpoints.getPhotos(lat, lon, page).url)
        debugPrint(request)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(nil, error)
                debugPrint("Error != nil")
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                    debugPrint("No data")
                }
                return
            }
            do {
                
                let response = try JSONDecoder().decode(PhotoSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.photos, nil)
                    debugPrint(response.photos)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                    debugPrint("Error decoding data. \(error)")
                }
            }
        }
        task.resume()
    }
    
    class func downloadPhoto(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, error)
                debugPrint("No data")
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
    
}
