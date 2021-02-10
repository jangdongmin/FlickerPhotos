//
//  SlideReactor.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import ReactorKit
import RxCocoa
import RxSwift

class SlideReactor: Reactor {
    let initialState = State()
    
    enum Action {
        case searchRandomTag
        case prepareImage(Int)
    }
    
    enum Mutation {
        case setIsDataLoading(Bool)
        case setImageObject([FlickrObject])
        case prepareImage(Int)
    }
    
    struct State {
        var isDataLoading: Bool = false
        var flickrObject: [FlickrObject] = []
        var currentImageIndex = 0
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .searchRandomTag:
                guard !(self.currentState.isDataLoading) else {
                    return Observable.empty()
                }
                 
                // random 값을 검색한다.
                return Observable.concat([
                    Observable.just(Mutation.setIsDataLoading(true)),
                    APIService.searchPhotos(keyword: randomString(length: 1)).catchAndReturn([]).map { Mutation.setImageObject($0) },
                    Observable.just(Mutation.setIsDataLoading(false))
                ])
            case let .prepareImage(count):
                //cache, disk에 이미지 저장해두기
                let flickrObject = self.currentState.flickrObject
                guard flickrObject.count > 0 else { return Observable.empty() }
               
                var sequences = [Observable<SlideReactor.Mutation>]()
                
                for i in 1..<(count + 1) {
                    if self.currentState.currentImageIndex + i >= flickrObject.count {
                        break
                    }
                    
                    let imageIndex = self.currentState.currentImageIndex //value copy!!!
                    // self.currentState.imageIndex 이걸 사용하면 레퍼런스 copy 가 된다.
                    sequences.append(APIService.downloadImage(url: flickrObject[imageIndex + i].media?.url ?? "").catchAndReturn(false).map { _ in Mutation.prepareImage(imageIndex + i) })
                }
                
                return Observable.merge( sequences )
            }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
            case let .setIsDataLoading(isLoading):
                newState.isDataLoading = isLoading
            case let .setImageObject(obj):
                newState.flickrObject.append(contentsOf: obj)
            case let .prepareImage(index):
                newState.currentImageIndex = index
        }
        return newState
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
  
