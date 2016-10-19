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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Top"
        
        self.nextButton.setTitle("Go Next", for: .normal)
        self.nextButton.addTarget(self, action: #selector(FirstViewController.goNextViewController), for: .touchUpInside)
        self.view.addSubview(self.nextButton)
        self.updateFrame()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.updateFrame()
    }
    
    func updateFrame() {
        self.nextButton.frame = CGRect.init(x: self.view.bounds.width/2 - 100, y: self.view.bounds.height/2 - 25, width: 200, height: 50)
    }
    
    func goNextViewController() {
        self.navigationController?.pushViewController(ViewController(), animated: true)
    }
}
