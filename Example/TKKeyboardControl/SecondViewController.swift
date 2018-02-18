//
//  SecondViewController.swift
//  TKKeyboardControl
//
//  Created by cztatsumi-keisuke on 04/25/2016.
//  Copyright (c) 2016 cztatsumi-keisuke. All rights reserved.
//

import UIKit
import TKKeyboardControl

class SecondViewController: UIViewController {

    let inputBaseView = UIView()
    let textField = UITextField()
    let sendButton = UIButton()
    
    let sideMargin: CGFloat = 5
    let inputBaseViewHeight: CGFloat = 40
    let textFieldHeight: CGFloat = 30
    let sendButtonWidth: CGFloat = 80

    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11, *) {
            return view.safeAreaInsets
        }
        return UIEdgeInsets.zero
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Second View"
        
        inputBaseView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        view.addSubview(inputBaseView)
        
        textField.backgroundColor = .white
        textField.placeholder = "Input here."
        textField.borderStyle = .roundedRect
        textField.textAlignment = .left
        inputBaseView.addSubview(textField)
        
        sendButton.setTitle("Send", for: .normal)
        inputBaseView.addSubview(sendButton)
        
        // Trigger Offset
        view.keyboardTriggerOffset = inputBaseViewHeight
        
        // Add Keyboard Pannning
        view.addKeyboardPanning(frameBasedActionHandler: { [weak self] keyboardFrameInView, firstResponder, opening, closing in
            guard let weakSelf = self else { return }
            if let v = firstResponder as? UIView {
                print("isDescendant of inputBaseView?: \(v.isDescendant(of: weakSelf.inputBaseView))")
            }

            weakSelf.inputBaseView.frame.origin.y = keyboardFrameInView.origin.y - weakSelf.inputBaseViewHeight
        })
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SecondViewController.closeKeyboard))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        updateFrame()
    }
    
    deinit {
        print("deinit called")
        view.removeKeyboardControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateFrame()
    }
    
    private func updateFrame() {
        inputBaseView.frame = CGRect(x: 0,
                                     y: view.bounds.size.height - inputBaseViewHeight - safeAreaInsets.bottom,
                                     width: view.bounds.size.width,
                                     height: inputBaseViewHeight)
        textField.frame = CGRect(x: sideMargin + safeAreaInsets.left,
                                 y: (inputBaseViewHeight - textFieldHeight)/2,
                                 width: view.bounds.size.width - sendButtonWidth - sideMargin * 3 - (safeAreaInsets.left + safeAreaInsets.right),
                                 height: textFieldHeight)
        sendButton.frame = CGRect(x: textField.frame.maxX + sideMargin,
                                  y: sideMargin,
                                  width: sendButtonWidth,
                                  height: textFieldHeight)
    }
    
    @objc private func closeKeyboard() {
        view.hideKeyboard()
    }
}

