//
//  ViewController.swift
//  TKKeyboardControl
//
//  Created by cztatsumi-keisuke on 04/25/2016.
//  Copyright (c) 2016 cztatsumi-keisuke. All rights reserved.
//

import UIKit
import TKKeyboardControl

class ViewController: UIViewController {

    let inputBaseView = UIView()
    let textField = UITextField()
    let sendButton = UIButton()
    
    let sideMargin: CGFloat = 5
    let inputBaseViewHeight: CGFloat = 40
    let textFieldHeight: CGFloat = 30
    let sendButtonWidth: CGFloat = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "TKKeyboardControl"
        
        inputBaseView.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        self.view.addSubview(inputBaseView)
        
        textField.backgroundColor = .whiteColor()
        textField.placeholder = "Input here."
        textField.borderStyle = .RoundedRect
        textField.textAlignment = .Left
        inputBaseView.addSubview(textField)
        
        sendButton.setTitle("Send", forState: .Normal)
        inputBaseView.addSubview(sendButton)
        
        // Trigger Offset
        self.view.keyboardTriggerOffset = self.inputBaseViewHeight
        
        // Add Keyboard Pannning
        self.view.addKeyboardPanningWithFrameBasedActionHandler({ [weak self] (keyboardFrameInView, opening, closing) in
            
            guard let weakSelf = self else { return }
            weakSelf.inputBaseView.frame.origin.y = keyboardFrameInView.origin.y - weakSelf.inputBaseViewHeight
            
            }, constraintBasedActionHandler: nil)
        
        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(ViewController.closeKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        self.updateFrame()
    }
    
    deinit {
        print("deinit called")
        self.view.removeKeyboardControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.updateFrame()
    }
    
    private func updateFrame() {
        inputBaseView.frame = CGRectMake(0, self.view.bounds.size.height - inputBaseViewHeight, self.view.bounds.size.width, inputBaseViewHeight)
        textField.frame = CGRectMake(sideMargin, (inputBaseViewHeight - textFieldHeight)/2, self.view.bounds.size.width - sendButtonWidth - sideMargin*3, textFieldHeight)
        sendButton.frame = CGRectMake(CGRectGetMaxX(textField.frame) + sideMargin, sideMargin, sendButtonWidth, textFieldHeight)
    }
    
    @objc private func closeKeyboard() {
        
        if self.view.isKeyboardOpened() {
            self.view.hideKeyboard()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

