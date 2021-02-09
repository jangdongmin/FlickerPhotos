//
//  UIImageView+Extension.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import UIKit

extension UIImageView {
    func fadeTo(_ alpha: CGFloat, duration: TimeInterval = 0.3, completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            UIView.animate(withDuration: duration)  {
                self.alpha = alpha
            } completion: { _ in
                completionHandler()
            }
        }
    }
    
    func fadeIn(_ duration: TimeInterval = 0.3, completionHandler: @escaping () -> Void) {
        fadeTo(1.0, duration: duration) {
            completionHandler()
        }
    }
    
    func fadeOut(_ duration: TimeInterval = 0.3, completionHandler: @escaping () -> Void) {
        fadeTo(0.0, duration: duration) {
            completionHandler()
        }
    }
}
