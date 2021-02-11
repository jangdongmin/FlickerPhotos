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
    
    func objectIsHidden(view: UIView, isHidden: Bool) {
        view.isHidden = isHidden
    }
    
    func bind(reactor: SlideReactor) {
        // start 버튼 눌렀을때, flicker 이미지를 가져온다
        startButton.rx.tapGesture().when(.recognized)
            .map { _ in Reactor.Action.searchRandomTag }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isDataLoading }
            .subscribe(onNext: { [weak self, weak reactor] in
                guard let `self` = self else { return }
                guard let reactor = reactor else { return }
                 
                if !$0 {
                    if reactor.currentState.flickrObject.count == 0 {
                        self.slideView.isLoading(isHidden: true)
                        self.objectIsHidden(view: self.startButton, isHidden: false)
                    }
                } else {
                    self.slideView.isLoading(isHidden: false)
                    self.objectIsHidden(view: self.startButton, isHidden: true)
                }
                    
            }).disposed(by: disposeBag)
        
        // flicker 에서 이미지(경로)를 가져왔다면, 처음 보여질 이미지 2개를 동시 다운로드 한다.
        // 이미지는 cache 또는 disk에 저장해둔다.
        reactor.state.map { $0.flickrObject }
            .observe(on: MainScheduler.asyncInstance)
            .filter {
                if $0.count == 0 {
                    return false
                }
                return true
            }
            .distinctUntilChanged { (last, new) in
                if last.count == new.count {
                    return true
                }
                return false
            }
            .compactMap { _ in Reactor.Action.prepareImage(2) } // 이미지 2개를 동시 다운로드
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

        // 이미지 다운로드가 완료되면, slideView의 setImageUrl에 넘겨준다.
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
            }).disposed(by: disposeBag)
    }
}

extension PhotoAlbumController: SlideViewDelegate {
    func remainImageCount(count: Int) {
        if let reactor = reactor {
            // 이미지를 미리 로드시켜둔다.
            Observable.just(Void())
                        .map { Reactor.Action.prepareImage(2) } //이미지 2개를 동시 다운로드
                        .bind(to: reactor.action)
                        .disposed(by: disposeBag)
        }
    }
}
  
