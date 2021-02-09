//
//  Constants.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import Foundation

struct APIUrl {
    static let baseURL = "https://www.flickr.com/services"
}

enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
}
