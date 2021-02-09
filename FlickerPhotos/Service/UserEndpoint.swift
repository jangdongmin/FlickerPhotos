//
//  UserEndpoint.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import Foundation
import Alamofire

protocol APIConfiguration: URLRequestConvertible {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters? { get }
}

enum UserEndpoint: APIConfiguration {
    case searchPhotos(keyword: String)
    
    var method: HTTPMethod {
        switch self {
            case .searchPhotos:
                return .get
        }
    }

    var path: String {
        switch self {
        case .searchPhotos:
            return "/feeds/photos_public.gne"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .searchPhotos(let keyword):
            return ["tags" : keyword,
                    "tagmode" : "any",
                    "nojsoncallback" : 1,                    
                    "format" : "json"]
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try APIUrl.baseURL.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        
        urlRequest.httpMethod = method.rawValue
         
        if let parameters = parameters {
            do {
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            } catch {
                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
            }
        }
        
        return urlRequest
    }
}
