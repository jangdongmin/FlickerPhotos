//
//  APIService.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper
import RxSwift
import SDWebImage

class APIService {
    static func searchPhotos(keyword: String) -> Observable<([FlickrObject])> {
        guard keyword != "" else {
            print("keyword empty")
            return .just([])
        }
        
        return Observable.create { observer -> Disposable in
            let request = UserEndpoint.searchPhotos(keyword: keyword)
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let value):
                    
                    if let result = JSON(value)["items"].rawString(),
                       let obj = Mapper<FlickrObject>().mapArray(JSONString: result) {
                        
                        observer.onNext(obj)
                    }
                    
                    observer.onCompleted()
                    
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    static func downloadImage(url: String) -> Observable<Bool> {
        guard url != "" else {
            print("url empty")
            return .just(false)
        }
         
        return Observable.create { observer -> Disposable in
            SDWebImageManager.shared.loadImage(with: URL(string: url), options: .highPriority, context: nil, progress: nil) { (image, data, error, cacheType, result, url) in
                if let err = error {
                    observer.onError(err)
                } else {
                    observer.onNext(true)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
