//
//  ViewController.swift
//  TKKeyboardControl
//
//  Created by cztatsumi-keisuke on 04/25/2016.
//  Copyright (c) 2016 cztatsumi-keisuke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let textField = UITextField()
    let textFieldHeight: CGFloat = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.frame = CGRectMake(10, self.view.bounds.size.height - textFieldHeight, self.view.bounds.size.width - 20, textFieldHeight);
        textField.backgroundColor = .whiteColor()
        textField.placeholder = "Input here!"
        textField.borderStyle = .Line
        textField.textAlignment = .Center
        
        // Trigger Offset
        self.view.keyboardTriggerOffset = self.textFieldHeight
        
        // Add Keyboard Pannning
        self.view.addKeyboardPanningWithFrameBasedActionHandler({ (keyboardFrameInView, opening, closing) in
            
            self.textField.frame.origin.y = keyboardFrameInView.origin.y - self.textFieldHeight
            
            }, constraintBasedActionHandler: nil)
        self.view.addSubview(textField)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

