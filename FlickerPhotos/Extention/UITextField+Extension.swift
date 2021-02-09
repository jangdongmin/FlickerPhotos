//
//  UITextField+Extension.swift
//  FlickerPhotos
//
//  Created by Paul Jang on 2021/02/08.
//

import UIKit
 
extension UITextField {
    @IBInspectable var doneAccessory: Bool {
        get {
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone {
                addButtonOnKeyboard()
            }
        }
    }
    
    func addButtonOnKeyboard() {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        let title = InputTextItem(text: self.text ?? "", font: .systemFont(ofSize: 16), color: .lightGray)
        let items = [title, flexSpace, done]
        toolbar.items = items
        toolbar.sizeToFit()
      
        self.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
    
    func setText(str: String) {
        self.text = str
        toolBarItemTextUpdate()
    }
    
    //textField가 키보드에 가려져 안보일 경우를 대비.
    func toolBarItemTextUpdate() {
        if let toolbar = self.inputAccessoryView as? UIToolbar, let item = toolbar.items {
            if item.count > 0, let label = item[0].customView as? UILabel {
                label.text = self.text
            }
        }
    }
}

class InputTextItem: UIBarButtonItem {

    init(text: String, font: UIFont, color: UIColor) {
        let label =  UILabel(frame: UIScreen.main.bounds)
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .left
        super.init()
        customView = label
    }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}
