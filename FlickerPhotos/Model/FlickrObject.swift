//
//  FlickrObject.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import ObjectMapper

struct FlickrObject: Mappable {
    init?(map: Map) {}
 
    var media: MediaObject?

    mutating func mapping(map: Map) {
        media <- map["media"]
    }
}

struct MediaObject: Mappable {
    init?(map: Map) {}
    
    var url: String?
    
    mutating func mapping(map: Map) {
        url <- map["m"]
    }
    
    func hash(into hasher: inout Hasher) {
       hasher.combine(url)
    }
}
