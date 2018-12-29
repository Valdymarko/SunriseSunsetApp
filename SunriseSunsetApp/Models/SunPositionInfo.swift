//
//  SunPositionInfo.swift
//  SunriseSunsetApp
//
//  Created by Володимир Ільків on 12/29/18.
//  Copyright © 2018 Володимр Ільків. All rights reserved.
//

import Foundation

class SunPositionInfo {
    
    let sunrise: String?
    let sunset: String?
    
    struct infoKeys {
        static let sunrise = "sunrise"
        static let sunset = "sunset"
    }
    
    init(infoDictionary: [String: Any]) {
        if let sunrise = infoDictionary[infoKeys.sunrise] {
            self.sunrise = sunrise as? String
        } else {
            self.sunrise = nil
        }
        if let sunset = infoDictionary[infoKeys.sunset] {
            self.sunset = sunset as? String
        } else {
            self.sunset = nil
        }
    }
    
    
}
