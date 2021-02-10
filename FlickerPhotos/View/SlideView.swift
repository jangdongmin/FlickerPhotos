//
//  SlideView.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import UIKit
import SDWebImage

protocol SlideViewDelegate: class {
    func remainImageCount(count: Int)
}

class SlideView: UIView {
    weak var delegate: SlideViewDelegate?
          
    @IBOutlet private weak var slideImageView: UIImageView!
    @IBOutlet private weak var timeIntervalTextField: UITextField!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    private var duration: TimeInterval = 2
    private var prepareImageMaxCount = 10 // 대기중인 이미지(경로) 최대 갯수
    private var isSliding = false
    
    // 이미지 경로를 저장한다.
    // 1. cache 또는 disk 에서 이미지를 가져오자
    // 2. 저장되어있는 이미지가 없을 경우 해당 URL에 이미지를 다운로드 한다.
    private var imageUrls = [String]() {
        didSet {
            if imageUrls.count == 0 {
                indicator.isHidden = false
            } else {
                indicator.isHidden = true
            }
        }
    }
         
    override func awakeFromNib() {
        let className = String(describing: type(of: self))
        let nib = UINib(nibName: className, bundle: Bundle.main)

        guard let xibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        xibView.frame = self.bounds
        xibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(xibView)
        
        textFieldInit()
    }
      
    // 슬라이드 시작
    func startSlide() {
        guard getSlidingState() == false else { return }
        
        setSlidingState(state: true)
        startAnimation()
    }
    
    // 슬라이드 종료
    func stopSlide() {
        stopAnimation()
    }
    
    // 이미지 보여지는 시간 설정
    func setDuration(time: Int) {
        duration = TimeInterval(time)
    }
    
    // 이미지 보여지는 시간
    func getDuration() -> Int {
        return Int(duration)
    }
    
    // 이미지 경로 저장
    func setImageUrl(urls: [String]) {
        imageUrls.append(contentsOf: urls)
    }
    
    // 대기중인 이미지(경로) 최대 갯수
    func setPrepareImageMaxCount(count: Int) {
        prepareImageMaxCount = count
    }
    
    // 대기중인 이미지(경로) 최대 갯수
    func getPrepareImageMaxCount() -> Int {
        return prepareImageMaxCount
    }
    
    // 슬라이드 시작여부
    func setSlidingState(state: Bool) {
        isSliding = state
    }
    
    // 슬라이드 시작여부
    func getSlidingState() -> Bool {
        return isSliding
    }
    
    func isLoading(isHidden: Bool) {
        indicator.isHidden = isHidden
    }
    
    private func textFieldInit() {
        timeIntervalTextField.delegate = self
        timeIntervalTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        timeIntervalTextField.setText(str: "\(Int(duration))")
    }
    
    private func startAnimation() {
        guard getSlidingState() == true else { return }
        guard imageUrls.count > 0 else {
            print("image count zero")
            setSlidingState(state: false)
            return
        }
        
        let imagePath = imageUrls[0]
        // 시간복잡도 O(k) = dropFirst
        // 이미지 보여준건 지우자.
        imageUrls = imageUrls.dropFirst().map { $0 }
        guard let url = URL(string: imagePath) else {
            print("url error")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
        
            // 1. SlideReactor 에서 이미지를 미리 로드한다. cache 또는 disk 에 저장해둠.
            // 2. 또는, 미리 로드 할 필요없이 이미지 경로만 있으면 load가 되게끔 만들었다.
            self.slideImageView.sd_setImage(with: url) { [weak self] (image, error, type, url) in
                guard let `self` = self else { return }
                guard error == nil else {
                    print(error ?? "image load error")
                    return
                }
                    
                // maximumSaveUrlCount 보다 적을 경우, remainImageCount 를 호출한다.
                // 현재 이미지(경로)의 수를 리턴한다.
                // 다음 이미지를 미리 로드시켜놓기 위해.
                if self.prepareImageMaxCount > self.imageUrls.count {
                    self.delegate?.remainImageCount(count: self.imageUrls.count)
                }

                self.slideImageView.fadeIn(self.duration) { [weak self] in
                    guard let `self` = self else { return }
        
                    self.slideImageView.fadeOut(self.duration) { [weak self] in
                        guard let `self` = self else { return }

                        self.startAnimation()
                    }
                }
            }
        }
    }
     
    private func stopAnimation() {
        setSlidingState(state: false)
        slideImageView.layer.removeAllAnimations()
    }
}

extension SlideView: UITextFieldDelegate {
    // textField 에 무조건 1~10초 사이의 값을 넣기 위함.
    @objc private func textFieldDidChange(textField: UITextField){
        guard let str = textField.text else { return }
        guard let intValue = Int(str) else {
            timeIntervalTextField.toolBarItemTextUpdate()
            return
        }
         
        if intValue > 10 {
            setDuration(time: 10)
            timeIntervalTextField.setText(str: "\(10)")
        } else if intValue == 0 {
            setDuration(time: 1)
            timeIntervalTextField.setText(str: "\(1)")
        } else {
            setDuration(time: intValue)
            self.timeIntervalTextField.toolBarItemTextUpdate()
        }
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            timeIntervalTextField.setText(str: "\(Int(duration))")
        }
    }
}
