//
//  TKKeyboardControl.swift
//
//  Created by 辰己 佳祐 on 2016/04/21.
//  Copyright © 2016年 Keisuke Tatsumi. All rights reserved.
//

import UIKit
import Foundation

public typealias TKKeyboardDidMoveBlock = ((_ keyboardFrameInView : CGRect, _ opening : Bool, _ closing : Bool) -> Void)?

private let frameKeyPath = "frame"

class TKKeyboardDidMoveBlockWrapper {
    var closure: TKKeyboardDidMoveBlock
    
    init(_ closure: TKKeyboardDidMoveBlock) {
        self.closure = closure
    }
}

class PreviousKeyboardRectWrapper {
    
    var closure: CGRect
    
    init(_ closure: CGRect) {
        self.closure = closure
    }
}

@inline(__always) func AnimationOptionsForCurve(_ curve: UIViewAnimationCurve) -> UIViewAnimationOptions {
    
    return UIViewAnimationOptions.init(rawValue: UInt(curve.rawValue))
}

public extension UIView {
    
    // MARK: - Public Properties
    
    dynamic var keyboardTriggerOffset : CGFloat {
        
        get {
            guard let triggerOffset: CGFloat = objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveTriggerOffset) as? CGFloat else {
                return 0
            }
            return triggerOffset
        }
        
        set {
            if let newValue : CGFloat = newValue {
                self.willChangeValue(forKey: "keyboardTriggerOffset");
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.DescriptiveTriggerOffset,
                                         newValue as CGFloat,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: "keyboardTriggerOffset");
            }
        }
    }
    
    var keyboardWillRecede : Bool {
        
        get {
            
            guard let activityView = self.keyboardActiveView else { return false }
            guard let activityViewSuperView = activityView.superview else { return false }
            guard let panGesture = self.keyboardPanRecognizer else { return false }
            
            let keyboardViewHeight = activityView.bounds.size.height
            let keyboardWindowHeight = activityViewSuperView.bounds.size.height;
            let touchLocationInKeyboardWindow = panGesture.location(in: activityViewSuperView)
            let thresholdHeight = keyboardWindowHeight - keyboardViewHeight - self.keyboardTriggerOffset + 44.0
            let velocity = panGesture.velocity(in: activityView)
            
            return touchLocationInKeyboardWindow.y >= thresholdHeight && velocity.y >= 0
        }
    }
    
    // MARK: - Public Methods
    
    func isKeyboardOpened() -> Bool {
        guard let isKeyboardOpened: Bool = self.keyboardOpened else {
            return false
        }
        return isKeyboardOpened
    }
    
    func addKeyboardPanningWithFrameBasedActionHandler(_ frameBasedActionHandler: TKKeyboardDidMoveBlock, constraintBasedActionHandler: TKKeyboardDidMoveBlock) {
        
        self.addKeyboardControl(true, frameBasedActionHandler: frameBasedActionHandler, constraintBasedActionHandler: constraintBasedActionHandler)
    }
    
    func addKeyboardNonpanningWithFrameBasedActionHandler(_ frameBasedActionHandler: TKKeyboardDidMoveBlock, constraintBasedActionHandler: TKKeyboardDidMoveBlock) {
        
        self.addKeyboardControl(false, frameBasedActionHandler: frameBasedActionHandler, constraintBasedActionHandler: constraintBasedActionHandler)
    }
    
    func keyboardFrameInView() -> CGRect {
        
        if let activityView = self.keyboardActiveView {
            
            let keyboardFrameInView = self.convert(activityView.frame, from: activityView.superview)
            return keyboardFrameInView
        }
        else {
            let keyboardFrameInView = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: 0, height: 0)
            return keyboardFrameInView
        }
    }
    
    func removeKeyboardControl() {
        
        // Unregister for text input notifications
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
        
        // Unregister for keyboard notifications
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        // For the sake of 4.X compatibility
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIKeyboardWillChangeFrameNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIKeyboardDidChangeFrameNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        // Unregister any gesture recognizer
        if let panRecognizer = self.keyboardPanRecognizer {
            self.removeGestureRecognizer(panRecognizer)
        }
        
        // Release a few properties
        self.frameBasedKeyboardDidMoveBlock = nil;
        self.keyboardActiveInput = nil;
        self.keyboardActiveView = nil;
        self.keyboardPanRecognizer = nil;
    }
    
    func hideKeyboard() {
        
        if self.keyboardActiveView != nil {
            self.keyboardActiveView?.isHidden = true
            self.keyboardActiveView?.isUserInteractionEnabled = false
            self.keyboardActiveInput?.resignFirstResponder()
        }
    }
}

fileprivate let swizzling: (UIView.Type) -> () = { view in
    let originalSelector = #selector(UIView.addSubview(_:))
    let swizzledSelector = #selector(UIView.swizzled_addSubview(_:))
    
    let originalMethod = class_getInstanceMethod(view, originalSelector)
    let swizzledMethod = class_getInstanceMethod(view, swizzledSelector)
    
    let didAddMethod = class_addMethod(view, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    
    if didAddMethod {
        class_replaceMethod(view, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIView : UIGestureRecognizerDelegate {
    
    fileprivate struct AssociatedKeys {
        static var DescriptiveTriggerOffset = "DescriptiveTriggerOffset"
        
        static var UIViewKeyboardTriggerOffset = "UIViewKeyboardTriggerOffset";
        static var UIViewKeyboardDidMoveFrameBasedBlock = "UIViewKeyboardDidMoveFrameBasedBlock";
        static var UIViewKeyboardDidMoveConstraintBasedBlock = "UIViewKeyboardDidMoveConstraintBasedBlock";
        static var UIViewKeyboardActiveInput = "UIViewKeyboardActiveInput";
        static var UIViewKeyboardActiveView = "UIViewKeyboardActiveView";
        static var UIViewKeyboardPanRecognizer = "UIViewKeyboardPanRecognizer";
        static var UIViewPreviousKeyboardRect = "UIViewPreviousKeyboardRect";
        static var UIViewIsPanning = "UIViewIsPanning";
        static var UIViewKeyboardOpened = "UIViewKeyboardOpened";
        static var UIViewKeyboardFrameObserved = "UIViewKeyboardFrameObserved";
    }
    
    fileprivate var frameBasedKeyboardDidMoveBlock : TKKeyboardDidMoveBlock {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardDidMoveFrameBasedBlock) as? TKKeyboardDidMoveBlockWrapper else {
                return nil
            }
            return cl.closure
        }
        
        set {
            self.willChangeValue(forKey: "frameBasedKeyboardDidMoveBlock")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardDidMoveFrameBasedBlock,
                                     TKKeyboardDidMoveBlockWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValue(forKey: "frameBasedKeyboardDidMoveBlock")
        }
    }
    
    fileprivate var constraintBasedKeyboardDidMoveBlock : TKKeyboardDidMoveBlock {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardDidMoveConstraintBasedBlock) as? TKKeyboardDidMoveBlockWrapper else {
                return nil
            }
            return cl.closure
        }
        
        set {
            self.willChangeValue(forKey: "constraintBasedKeyboardDidMoveBlock")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardDidMoveConstraintBasedBlock,
                                     TKKeyboardDidMoveBlockWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValue(forKey: "constraintBasedKeyboardDidMoveBlock")
        }
    }
    
    fileprivate var keyboardActiveInput : UIResponder? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardActiveInput) as? UIResponder
        }
        
        set {
            if let newValue : UIResponder = newValue {
                self.willChangeValue(forKey: "keyboardActiveInput")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardActiveInput,
                                         newValue as UIResponder,
                                         .OBJC_ASSOCIATION_RETAIN)
                self.didChangeValue(forKey: "keyboardActiveInput")
            }
        }
    }
    
    fileprivate var keyboardActiveView : UIView? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardActiveView) as? UIView
        }
        
        set {
            if let newValue : UIView = newValue {
                self.willChangeValue(forKey: "keyboardActiveView")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardActiveView,
                                         newValue as UIView,
                                         .OBJC_ASSOCIATION_RETAIN)
                self.didChangeValue(forKey: "keyboardActiveView")
            }
        }
    }
    
    fileprivate var keyboardPanRecognizer : UIPanGestureRecognizer? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardPanRecognizer) as? UIPanGestureRecognizer
        }
        
        set {
            if let newValue : UIPanGestureRecognizer = newValue {
                self.willChangeValue(forKey: "keyboardPanRecognizer")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardPanRecognizer,
                                         newValue as UIPanGestureRecognizer,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: "keyboardPanRecognizer")
            }
        }
    }
    
    fileprivate var previousKeyboardRect : CGRect {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewPreviousKeyboardRect) as? PreviousKeyboardRectWrapper else {
                return CGRect.zero
            }
            return cl.closure
        }
        
        set {
            self.willChangeValue(forKey: "previousKeyboardRect")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewPreviousKeyboardRect,
                                     PreviousKeyboardRectWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.didChangeValue(forKey: "previousKeyboardRect")
        }
    }
    
    fileprivate var panning : Bool {
        
        get {
            guard let isPanningNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewIsPanning) as? NSNumber else {
                return false
            }
            return isPanningNumber.boolValue
        }
        
        set {
            if let newValue : Bool = newValue {
                self.willChangeValue(forKey: "panning");
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewIsPanning,
                                         NSNumber(value: newValue as Bool),
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: "panning");
            }
        }
    }
    
    fileprivate var keyboardOpened : Bool {
        
        get {
            guard let isKeyboardOpenedNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardOpened) as? NSNumber else {
                return false
            }
            return isKeyboardOpenedNumber.boolValue
        }
        
        set {
            if let newValue : Bool = newValue {
                self.willChangeValue(forKey: "keyboardOpened");
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardOpened,
                                         NSNumber(value: newValue as Bool),
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: "keyboardOpened");
            }
        }
    }
    
    fileprivate var keyboardFrameObserved : Bool {
        
        get {
            guard let isKeyboardFrameObservedNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardFrameObserved) as? NSNumber else {
                return false
            }
            return isKeyboardFrameObservedNumber.boolValue
        }
        
        set {
            if let newValue : Bool = newValue {
                self.willChangeValue(forKey: "keyboardFrameObserved");
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardFrameObserved,
                                         NSNumber(value: newValue as Bool),
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: "keyboardFrameObserved");
            }
        }
    }
    
    open override class func initialize() {
        
        struct Static {
            static var token: Int = 0
        }
        
        if self !== UIView.self {
            return
        }
        
        swizzling(self)
    }
    
    // MARK: Add Keyboard Control
    
    fileprivate func addKeyboardControl(_ panning: Bool, frameBasedActionHandler: TKKeyboardDidMoveBlock, constraintBasedActionHandler: TKKeyboardDidMoveBlock) {
        
        if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0 {
            if panning && self.responds(to: #selector(getter: UIScrollView.keyboardDismissMode)) {
                if let scrollView = self as? UIScrollView {
                    scrollView.keyboardDismissMode = .interactive
                }
            }
        }
        
        self.panning = panning
        
        self.frameBasedKeyboardDidMoveBlock = frameBasedActionHandler
        self.constraintBasedKeyboardDidMoveBlock = constraintBasedActionHandler
        
        // Register for text input notifications
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.responderDidBecomeActive(_:)), name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.responderDidBecomeActive(_:)), name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        // For the sake of 4.X compatibility
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardWillChangeFrame(_:)), name: NSNotification.Name(rawValue: "UIKeyboardWillChangeFrameNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardDidChangeFrame), name: NSNotification.Name(rawValue: "UIKeyboardDidChangeFrameNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIView.inputKeyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    // MARK: - Input Notifications
    
    func responderDidBecomeActive(_ notification: Notification) {
        
        self.keyboardActiveInput = notification.object as? UIResponder
        if self.keyboardActiveInput?.inputAccessoryView == nil {
            
            let textField = self.keyboardActiveInput as! UITextField
            if textField.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                let nullView: UIView = UIView(frame: CGRect.zero)
                nullView.backgroundColor = .clear
                textField.inputAccessoryView = nullView
            }
            self.keyboardActiveInput = textField as UIResponder
            self.inputKeyboardDidShow()
        }
    }
    
    // MARK: - Keyboard Notifications
    
    func inputKeyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }

        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = UIViewAnimationCurve.easeInOut
        if (((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve) != nil) {
            keyboardTransitionAnimationCurve = ((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve)!
        }

        self.keyboardActiveView?.isHidden = false
        self.keyboardOpened = true
        
        let keyboardEndFrameView = self.convert(keyboardEndFrameWindow, from: nil)
        
        let constraintBasedKeyboardDidMoveBlockCalled = (self.constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            
            self.constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, true, false)
        }
        
        UIView.animate(withDuration: keyboardTransitionDuration,
                       delay: 0,
                       options: [AnimationOptionsForCurve(keyboardTransitionAnimationCurve), .beginFromCurrentState],
                       animations: {
                        
                        if constraintBasedKeyboardDidMoveBlockCalled {
                            self.layoutIfNeeded()
                        }
                        if self.frameBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull {
                            self.frameBasedKeyboardDidMoveBlock?(keyboardEndFrameView, true, false)
                        }
        }) { (finished: Bool) in
            if self.panning {
                
                self.keyboardPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(UIView.panGestureDidChange(_:)))
                self.keyboardPanRecognizer?.minimumNumberOfTouches = 1
                self.keyboardPanRecognizer?.delegate = self
                self.keyboardPanRecognizer?.cancelsTouchesInView = false
                
                guard let panGesture = self.keyboardPanRecognizer else { return }
                self.addGestureRecognizer(panGesture)
            }
        }
    }
    
    func inputKeyboardDidShow() {
        self.keyboardActiveView = self.findInputSetHostView()
        self.keyboardActiveView?.isHidden = false
        
        if self.keyboardActiveView == nil {
            
            self.keyboardActiveInput = self.recursiveFindFirstResponder(self)
            self.keyboardActiveView = self.findInputSetHostView()
            self.keyboardActiveView?.isHidden = false
        }
        
        if !self.keyboardFrameObserved {
            self.keyboardActiveView?.addObserver(self, forKeyPath: frameKeyPath, options: .new, context: nil)
            self.keyboardFrameObserved = true
        }
    }
    
    func inputKeyboardWillChangeFrame(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }
        
        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = UIViewAnimationCurve.easeInOut
        if (((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve) != nil) {
            keyboardTransitionAnimationCurve = ((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve)!
        }
        
        let keyboardEndFrameView = self.convert(keyboardEndFrameWindow, from: nil)
        
        let constraintBasedKeyboardDidMoveBlockCalled = (self.constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            
            self.constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, false)
        }
        
        UIView.animate(withDuration: keyboardTransitionDuration,
                       delay: 0,
                       options: [AnimationOptionsForCurve(keyboardTransitionAnimationCurve), .beginFromCurrentState],
                       animations: {
                        
                        if constraintBasedKeyboardDidMoveBlockCalled {
                            self.layoutIfNeeded()
                        }
                        if self.frameBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull {
                            self.frameBasedKeyboardDidMoveBlock?(keyboardEndFrameView, false, false)
                        }
            }, completion:nil)
    }
    
    func inputKeyboardDidChangeFrame() {
        // Nothing to see here
    }
    
    func inputKeyboardWillHide(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }
        
        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = UIViewAnimationCurve.easeInOut
        if (((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve) != nil) {
            keyboardTransitionAnimationCurve = ((userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)!.intValue << 16 as? UIViewAnimationCurve)!
        }
        
        let keyboardEndFrameView = self.convert(keyboardEndFrameWindow, from: nil)
        
        let constraintBasedKeyboardDidMoveBlockCalled = (self.constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            
            self.constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, true)
        }
        
        UIView.animate(withDuration: keyboardTransitionDuration,
                       delay: 0,
                       options: [AnimationOptionsForCurve(keyboardTransitionAnimationCurve), .beginFromCurrentState],
                       animations: {
                        
                        if constraintBasedKeyboardDidMoveBlockCalled {
                            self.layoutIfNeeded()
                        }
                        if self.frameBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull {
                            self.frameBasedKeyboardDidMoveBlock?(keyboardEndFrameView, false, true)
                        }
        }) { (finished: Bool) in
            if let panRecognizer = self.keyboardPanRecognizer {
                self.removeGestureRecognizer(panRecognizer)
            }
            self.keyboardPanRecognizer = nil
            
            if self.keyboardFrameObserved {
                self.keyboardActiveView?.removeObserver(self, forKeyPath: frameKeyPath)
                self.keyboardFrameObserved = false
            }
        }
    }
    
    func inputKeyboardDidHide() {
        
        self.keyboardActiveView?.isHidden = false
        self.keyboardActiveView?.isUserInteractionEnabled = true
        self.keyboardActiveView = nil
        self.keyboardActiveInput = nil
        self.keyboardOpened = false
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        if keyPath == frameKeyPath && object as? UIView == self.keyboardActiveView {
            guard let keyboardEndFrameWindow = (object as? UIView)?.frame else { return }
            guard var keyboardEndFrameView = self.keyboardActiveView?.frame else { return }
            keyboardEndFrameView.origin.y = keyboardEndFrameWindow.origin.y
            
            if keyboardEndFrameView.equalTo(self.previousKeyboardRect) {
                return
            }
            
            guard let activityView = self.keyboardActiveView else { return }
            
            if !activityView.isHidden && !keyboardEndFrameView.isNull {
                
                if self.frameBasedKeyboardDidMoveBlock != nil {
                    self.frameBasedKeyboardDidMoveBlock?(keyboardEndFrameView, false, false)
                }
                
                if self.constraintBasedKeyboardDidMoveBlock != nil {
                    self.constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, false)
                    self.layoutIfNeeded()
                }
            }
            
            self.previousKeyboardRect = keyboardEndFrameView
        }
    }
    
    // MARK: - Touches Management
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == self.keyboardPanRecognizer || otherGestureRecognizer == self.keyboardPanRecognizer {
            return true
        }
        else {
            return false
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer == self.keyboardPanRecognizer {
            
            guard let touchView = touch.view else { return true }
            
            return (!touchView.isFirstResponder || (self.isKind(of: UITextView.self) && self.isEqual(touchView)))
        }
        else {
            return true
        }
    }
    
    func panGestureDidChange(_ gesture: UIPanGestureRecognizer) {
        
        if self.keyboardActiveView == nil || self.keyboardActiveInput == nil || (self.keyboardActiveView?.isHidden)! {
            
            self.keyboardActiveInput = self.recursiveFindFirstResponder(self)
            self.keyboardActiveView = self.findInputSetHostView()
            self.keyboardActiveView?.isHidden = false
        }
        else {
            
            self.keyboardActiveView?.isHidden = false
        }
        
        guard let activityView = self.keyboardActiveView else { return }
        guard let activityViewSuperView = activityView.superview else { return }
        
        let keyboardViewHeight : CGFloat = activityView.bounds.size.height
        let keyboardWindowHeight : CGFloat = activityViewSuperView.bounds.size.height
        let touchLocationInKeyboardWindow = gesture.location(in: activityView.superview)
        
        if touchLocationInKeyboardWindow.y > keyboardWindowHeight - keyboardViewHeight - self.keyboardTriggerOffset {
            
            activityView.isUserInteractionEnabled = false
        }
        else {
            
            activityView.isUserInteractionEnabled = true
        }
        
        switch gesture.state {
        case .began:
            
            gesture.maximumNumberOfTouches = gesture.numberOfTouches
            break
            
        case .changed:
            var newKeyboardViewFrame = activityView.frame
            newKeyboardViewFrame.origin.y = touchLocationInKeyboardWindow.y + self.keyboardTriggerOffset
            newKeyboardViewFrame.origin.y = min(newKeyboardViewFrame.origin.y, keyboardWindowHeight)
            newKeyboardViewFrame.origin.y = max(newKeyboardViewFrame.origin.y, keyboardWindowHeight - keyboardViewHeight)
            
            if newKeyboardViewFrame.origin.y != self.keyboardActiveView?.frame.origin.y {
                
                UIView.animate(withDuration: 0,
                               delay: 0,
                               options: .beginFromCurrentState,
                               animations: {
                                
                                activityView.frame = newKeyboardViewFrame
                    }, completion: nil)
            }
            
            break
            
        case .ended, .cancelled:
            
            let thresholdHeight = keyboardWindowHeight - keyboardViewHeight - self.keyboardTriggerOffset + 44
            let velocity = gesture.velocity(in: self.keyboardActiveView)
            var shouldRecede = Bool()
            
            if touchLocationInKeyboardWindow.y < thresholdHeight || velocity.y < 0 {
                shouldRecede = false
            }
            else {
                shouldRecede = true
            }
            
            var newKeyboardViewFrame = activityView.frame
            newKeyboardViewFrame.origin.y = !shouldRecede ? keyboardWindowHeight - keyboardViewHeight : keyboardWindowHeight
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseOut, .beginFromCurrentState],
                           animations: {
                            activityView.frame = newKeyboardViewFrame
                }, completion: { (finished: Bool) in
                    
                    activityView.isUserInteractionEnabled = !shouldRecede
                    
                    if shouldRecede {
                        self.hideKeyboard()
                    }
            })
            gesture.maximumNumberOfTouches = LONG_MAX
            
            break
        default:
            break
        }
    }
    
    // MARK: - Internal Methods
    
    func recursiveFindFirstResponder(_ view: UIView) -> UIView? {
        
        if view.isFirstResponder {
            return view
        }
        var found: UIView? = nil
        for v in view.subviews {
            
            found = self.recursiveFindFirstResponder(v)
            if found != nil {
                break
            }
        }
        return found
    }
    
    func findInputSetHostView() -> UIView? {
        
        if #available(iOS 9, *) {
            
            guard let remoteKeyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow") else { return nil }
            guard let inputSetHostViewClass = NSClassFromString("UIInputSetHostView") else { return nil }
            
            for window in UIApplication.shared.windows {
                if window.isKind(of: remoteKeyboardWindowClass) {
                    for subView in window.subviews {
                        if subView.isKind(of: inputSetHostViewClass) {
                            for subSubView in subView.subviews {
                                if subSubView.isKind(of: inputSetHostViewClass) {
                                    return subSubView
                                }
                            }
                        }
                    }
                }
            }
        }
        else {
            return self.keyboardActiveInput?.inputAccessoryView?.superview
        }
        
        return nil
    }
    
    func swizzled_addSubview(_ subView: UIView) {
        
        if subView.inputAccessoryView == nil  {
            
            if subView.isKind(of: UITextField.self) {
                let textField = subView as! UITextField
                if textField.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                    let nullView: UIView = UIView(frame: CGRect.zero)
                    nullView.backgroundColor = .clear
                    textField.inputAccessoryView = nullView
                }
            }
            else if subView.isKind(of: UITextView.self) {
                let textView = subView as! UITextView
                if textView.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                    let nullView: UIView = UIView(frame: CGRect.zero)
                    nullView.backgroundColor = .clear
                    textView.inputAccessoryView = nullView
                }
            }
        }
        self.swizzled_addSubview(subView)
    }
}
