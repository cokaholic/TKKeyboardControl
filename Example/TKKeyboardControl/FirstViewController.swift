//
//  FirstViewController.swift
//  TKKeyboardControl
//
//  Created by 辰己 佳祐 on 2016/06/01.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

final class FirstViewController: UIViewController {
    
    let nextButton = UIButton(type: .system)
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
        
        title = "First View"

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

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FirstViewController.closeKeyboard))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        nextButton.setTitle("Go Next", for: .normal)
        nextButton.addTarget(self, action: #selector(FirstViewController.goNextViewController), for: .touchUpInside)
        view.addSubview(nextButton)
        updateFrame()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Add Keyboard Pannning
        view.addKeyboardPanning(frameBasedActionHandler: { [weak self] keyboardFrameInView, firstResponder, opening, closing in
            guard let weakSelf = self else { return }
            if let v = firstResponder as? UIView {
                print("isDescendant of inputBaseView?: \(v.isDescendant(of: weakSelf.inputBaseView))")
            }

            weakSelf.inputBaseView.frame.origin.y = keyboardFrameInView.origin.y - weakSelf.inputBaseViewHeight
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.removeKeyboardControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.updateFrame()
    }
    
    func updateFrame() {
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
        nextButton.frame = CGRect(x: view.bounds.width/2 - 100,
                                  y: view.bounds.height/2 - 25,
                                  width: 200,
                                  height: 50)
    }

    @objc private func closeKeyboard() {
        view.hideKeyboard()
    }
    
    @objc func goNextViewController() {

        // - Attention: You should call close keyboard before begin transitioning
        closeKeyboard()
        navigationController?.pushViewController(SecondViewController(), animated: true)
    }
}
