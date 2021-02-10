//
//  PhotoAlbumController.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import RxGesture

class PhotoAlbumController: UIViewController, StoryboardView {
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var slideView: SlideView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slideView.delegate = self
        
        self.reactor = SlideReactor()
    }
    
    func bind(reactor: SlideReactor) {
        // start 버튼 눌렀을때, flicker 이미지를 가져온다
        startButton.rx.tapGesture().when(.recognized)
            .map { _ in Reactor.Action.searchRandomTag }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // flicker 이미지 경로를  가져왔다면, 이미지를 로드한다.
        // 이미지는 cache 또는 disk에 저장해둔다.
        reactor.state.map { $0.flickrObject }.distinctUntilChanged { (last, new) in
            if new.count != 0, last.count == new.count {
                return true
            }
            return false
        }.observe(on: MainScheduler.asyncInstance)
        .compactMap { _ in Reactor.Action.prepareImage(2) } //처음 몇개 로드할껀지 셋팅 할 수 있다.
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // SlideShow가 끊기지 않고 계속 새로운 이미지를 보여주기 위함.
        reactor.state.map { $0.currentImageIndex }
            .observe(on: MainScheduler.asyncInstance)
            .filter { _ in
                let flickrObject = reactor.currentState.flickrObject
                if flickrObject.count / 2 < reactor.currentState.currentImageIndex {
                    return true
                }

                return false
            }
            .map { _ in Reactor.Action.searchRandomTag }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 다음 이미지를 보여줄떄마다 currentImageIndex를 + 1 씩 증가시킨다.
        reactor.state.map { $0.currentImageIndex }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self, weak reactor] in

                guard let `self` = self else { return }
                guard let reactor = reactor else { return }
                guard $0 != 0 else { return }

                let flickrObject = reactor.currentState.flickrObject
                guard flickrObject.count > 0, flickrObject.count > ($0 - 1) else {
                    print("index out of range")
                    return
                }
                
                if let url = flickrObject[($0 - 1)].media?.url {
                    // slideView에 이미지 경로를 넘긴다.
                    self.slideView.setImageUrl(urls: [url])
                }

                // slide 스타트
                self.slideView.startSlide()
                self.startButton.isHidden = true

            }).disposed(by: disposeBag)
    }
}

extension PhotoAlbumController: SlideViewDelegate {
    func remainImageCount(count: Int) {
        if let reactor = reactor {            
            // 이미지를 미리 로드시켜둔다.
            Observable.just(Void())
                        .map { Reactor.Action.prepareImage(2) }
                        .bind(to: reactor.action)
                        .disposed(by: disposeBag)            
        }
    }
}
  
