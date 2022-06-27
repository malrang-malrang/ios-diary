//
//  URLSessionGenerator.swift
//  Diary
//
//  Created by mmim, grumpy, mino on 2022/06/23.
//

import Foundation

enum EndPoint {
    private enum Constants {
        static let weatherInfoURL = "https://api.openweathermap.org/data/2.5/weather?"
        static let weatherIconURL = "https://openweathermap.org/img/wn/"
        static let appkey = "5d541eac3b64ce81f672025857e60683"
    }
    
    case weatherInfo(_ latitude: Double, _ longitude: Double)
    case weatherIcon(_ icon: String)
    
    var url: URL? {
        switch self {
        case .weatherInfo(let latitude, let longitude):
            return URL(string: "\(Constants.weatherInfoURL)lat=\(latitude)&lon=\(longitude)&appid=\(Constants.appkey)")
        case .weatherIcon(let icon):
            return URL(string: "\(Constants.weatherIconURL)\(icon)@2x.png")
        }
    }
}