//
//  SunInfoService.swift
//  SunriseSunsetApp
//
//  Created by Володимир Ільків on 12/29/18.
//  Copyright © 2018 Володимр Ільків. All rights reserved.
//

import Foundation


class  SunInfoService{
    
    static let shared = SunInfoService()
    
    private let baseUrl = "https://api.sunrise-sunset.org/json?"
    private let httpMethod = "GET"
    private let session = URLSession(configuration: .default)
    
     func getSunPositionInfo(latitude: Double, longitude: Double, completion:  @escaping (SunPositionInfo?) -> Void){
        guard let urlComponents = URLComponents(string: baseUrl + "lat=\(latitude)&lng=\(longitude)" + "&formatted=0") else {
            completion(nil)
            return
        }
        
        guard let url = urlComponents.url else {
            completion(nil)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod
        
        let task = session.dataTask(with: urlRequest){ (data, response, error) in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                (200 ..< 300) ~= response.statusCode,
                error == nil else {
                    completion(nil)
                    return
            }
            
            if let stringJSON = String(data: data, encoding: String.Encoding.utf8) {
                if let data = stringJSON.data(using: String.Encoding.utf8) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
                        let responseDictionary = json!["results"] as! [String : Any]
                        let sunInfo = SunPositionInfo(infoDictionary: responseDictionary)
                        completion(sunInfo)
                    } catch {
                        print("Something went wrong")
                    }
                }
            }

            
        }
    
        task.resume()
        
    }
    
    
    
}
