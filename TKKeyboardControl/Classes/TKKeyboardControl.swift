//
//  TKKeyboardControl.swift
//
//  Created by 辰己 佳祐 on 2016/04/21.
//  Copyright © 2016年 Keisuke Tatsumi. All rights reserved.
//

import UIKit
import Foundation

public typealias TKKeyboardDidMoveBlock = ((_ keyboardFrameInView: CGRect, _ opening: Bool, _ closing: Bool) -> Void)?

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
    
    return UIViewAnimationOptions(rawValue: UInt(curve.rawValue))
}

public extension UIView {
    
    // MARK: - Public Properties
    
    @objc dynamic var keyboardTriggerOffset: CGFloat {
        
        get {
            guard let triggerOffset: CGFloat = objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveTriggerOffset) as? CGFloat else {
                return 0
            }
            return triggerOffset
        }
        
        set {
            willChangeValue(forKey: "keyboardTriggerOffset")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.DescriptiveTriggerOffset,
                                     newValue as CGFloat,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "keyboardTriggerOffset")
        }
    }
    
    var keyboardWillRecede: Bool {
        
        get {
            guard let activityView = keyboardActiveView else { return false }
            guard let activityViewSuperView = activityView.superview else { return false }
            guard let panGesture = keyboardPanRecognizer else { return false }
            
            let keyboardViewHeight = activityView.bounds.size.height
            let keyboardWindowHeight = activityViewSuperView.bounds.size.height
            let touchLocationInKeyboardWindow = panGesture.location(in: activityViewSuperView)
            let thresholdHeight = keyboardWindowHeight - keyboardViewHeight - keyboardTriggerOffset + 44.0
            let velocity = panGesture.velocity(in: activityView)
            
            return touchLocationInKeyboardWindow.y >= thresholdHeight && velocity.y >= 0
        }
    }
    
    // MARK: - Public Methods
    
    func isKeyboardOpened() -> Bool {
        return keyboardOpened
    }
    
    func addKeyboardPanning(frameBasedActionHandler: TKKeyboardDidMoveBlock? = nil, constraintBasedActionHandler: TKKeyboardDidMoveBlock? = nil) {
        addKeyboardControl(panning: true, frameBasedActionHandler: frameBasedActionHandler, constraintBasedActionHandler: constraintBasedActionHandler)
    }
    
    func addKeyboardNonpanning(frameBasedActionHandler: TKKeyboardDidMoveBlock? = nil, constraintBasedActionHandler: TKKeyboardDidMoveBlock? = nil) {
        addKeyboardControl(panning: false, frameBasedActionHandler: frameBasedActionHandler, constraintBasedActionHandler: constraintBasedActionHandler)
    }

    func keyboardFrameInView() -> CGRect {
        
        if let activityView = keyboardActiveView {
            
            let keyboardFrameInView = convert(activityView.frame, from: activityView.superview)
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
        if let panRecognizer = keyboardPanRecognizer {
            removeGestureRecognizer(panRecognizer)
        }

        // Release a few properties
        frameBasedKeyboardDidMoveBlock = nil
        constraintBasedKeyboardDidMoveBlock = nil
        keyboardActiveInput = nil
        keyboardActiveView = nil
        keyboardPanRecognizer = nil
    }

    func hideKeyboard() {
        hideKeyboard(isKeyboardViewHidden: false)
    }
}

fileprivate let swizzling: (UIView.Type) -> () = { view in
    let originalSelector = #selector(UIView.addSubview(_:))
    let swizzledSelector = #selector(UIView.swizzled_addSubview(_:))
    
    let originalMethod = class_getInstanceMethod(view, originalSelector)
    let swizzledMethod = class_getInstanceMethod(view, swizzledSelector)
    
    let didAddMethod = class_addMethod(view, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
    
    if didAddMethod {
        class_replaceMethod(view, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
    } else {
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
}

extension UIView: UIGestureRecognizerDelegate {
    
    fileprivate struct AssociatedKeys {
        static var DescriptiveTriggerOffset = "DescriptiveTriggerOffset"
        
        static var UIViewKeyboardTriggerOffset = "UIViewKeyboardTriggerOffset"
        static var UIViewKeyboardDidMoveFrameBasedBlock = "UIViewKeyboardDidMoveFrameBasedBlock"
        static var UIViewKeyboardDidMoveConstraintBasedBlock = "UIViewKeyboardDidMoveConstraintBasedBlock"
        static var UIViewKeyboardActiveInput = "UIViewKeyboardActiveInput"
        static var UIViewKeyboardActiveView = "UIViewKeyboardActiveView"
        static var UIViewKeyboardPanRecognizer = "UIViewKeyboardPanRecognizer"
        static var UIViewPreviousKeyboardRect = "UIViewPreviousKeyboardRect"
        static var UIViewIsPanning = "UIViewIsPanning"
        static var UIViewKeyboardOpened = "UIViewKeyboardOpened"
        static var UIViewKeyboardFrameObserved = "UIViewKeyboardFrameObserved"
    }
    
    fileprivate var frameBasedKeyboardDidMoveBlock: TKKeyboardDidMoveBlock {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardDidMoveFrameBasedBlock) as? TKKeyboardDidMoveBlockWrapper else {
                return nil
            }
            return cl.closure
        }
        
        set {
            willChangeValue(forKey: "frameBasedKeyboardDidMoveBlock")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardDidMoveFrameBasedBlock,
                                     TKKeyboardDidMoveBlockWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN)
            didChangeValue(forKey: "frameBasedKeyboardDidMoveBlock")
        }
    }
    
    fileprivate var constraintBasedKeyboardDidMoveBlock: TKKeyboardDidMoveBlock {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardDidMoveConstraintBasedBlock) as? TKKeyboardDidMoveBlockWrapper else {
                return nil
            }
            return cl.closure
        }
        
        set {
            willChangeValue(forKey: "constraintBasedKeyboardDidMoveBlock")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardDidMoveConstraintBasedBlock,
                                     TKKeyboardDidMoveBlockWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN)
            didChangeValue(forKey: "constraintBasedKeyboardDidMoveBlock")
        }
    }
    
    fileprivate var keyboardActiveInput: UIResponder? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardActiveInput) as? UIResponder
        }
        
        set {
            if let newValue: UIResponder = newValue {
                willChangeValue(forKey: "keyboardActiveInput")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardActiveInput,
                                         newValue as UIResponder,
                                         .OBJC_ASSOCIATION_RETAIN)
                didChangeValue(forKey: "keyboardActiveInput")
            }
        }
    }
    
    fileprivate var keyboardActiveView: UIView? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardActiveView) as? UIView
        }
        
        set {
            if let newValue: UIView = newValue {
                willChangeValue(forKey: "keyboardActiveView")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardActiveView,
                                         newValue as UIView,
                                         .OBJC_ASSOCIATION_RETAIN)
                didChangeValue(forKey: "keyboardActiveView")
            }
        }
    }
    
    fileprivate var keyboardPanRecognizer: UIPanGestureRecognizer? {
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardPanRecognizer) as? UIPanGestureRecognizer
        }
        
        set {
            if let newValue: UIPanGestureRecognizer = newValue {
                willChangeValue(forKey: "keyboardPanRecognizer")
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.UIViewKeyboardPanRecognizer,
                                         newValue as UIPanGestureRecognizer,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                didChangeValue(forKey: "keyboardPanRecognizer")
            }
        }
    }
    
    fileprivate var previousKeyboardRect: CGRect {
        
        get {
            guard let cl = objc_getAssociatedObject(self, &AssociatedKeys.UIViewPreviousKeyboardRect) as? PreviousKeyboardRectWrapper else {
                return CGRect.zero
            }
            return cl.closure
        }
        
        set {
            willChangeValue(forKey: "previousKeyboardRect")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewPreviousKeyboardRect,
                                     PreviousKeyboardRectWrapper(newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "previousKeyboardRect")
        }
    }
    
    fileprivate var panning: Bool {
        
        get {
            guard let isPanningNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewIsPanning) as? NSNumber else {
                return false
            }
            return isPanningNumber.boolValue
        }
        
        set {
            willChangeValue(forKey: "panning")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewIsPanning,
                                     NSNumber(value: newValue as Bool),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "panning")
        }
    }
    
    fileprivate var keyboardOpened: Bool {
        
        get {
            guard let isKeyboardOpenedNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardOpened) as? NSNumber else {
                return false
            }
            return isKeyboardOpenedNumber.boolValue
        }
        
        set {
            willChangeValue(forKey: "keyboardOpened")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardOpened,
                                     NSNumber(value: newValue as Bool),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "keyboardOpened")
        }
    }
    
    fileprivate var keyboardFrameObserved: Bool {
        
        get {
            guard let isKeyboardFrameObservedNumber: NSNumber = objc_getAssociatedObject(self, &AssociatedKeys.UIViewKeyboardFrameObserved) as? NSNumber else {
                return false
            }
            return isKeyboardFrameObservedNumber.boolValue
        }
        
        set {
            willChangeValue(forKey: "keyboardFrameObserved")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.UIViewKeyboardFrameObserved,
                                     NSNumber(value: newValue as Bool),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            didChangeValue(forKey: "keyboardFrameObserved")
        }
    }

    fileprivate var safeAreaBottomInset: CGFloat {
        if #available(iOS 11, *) {
            return safeAreaInsets.bottom
        }
        return 0
    }
    
    fileprivate class func initializeControl() {
        
        struct Static {
            static var token: Int = 0
        }
        
        if self !== UIView.self {
            return
        }
        
        swizzling(self)
    }
    
    // MARK: Add Keyboard Control
    
    fileprivate func addKeyboardControl(panning: Bool, frameBasedActionHandler: TKKeyboardDidMoveBlock?, constraintBasedActionHandler: TKKeyboardDidMoveBlock?) {

        // Avoid twice registration
        removeKeyboardControl()
        
        if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0 {
            if panning && responds(to: #selector(getter: UIScrollView.keyboardDismissMode)) {
                if let scrollView = self as? UIScrollView {
                    scrollView.keyboardDismissMode = .interactive
                }
            }
        }
        
        self.panning = panning

        if let frameBasedActionHandler = frameBasedActionHandler {
            frameBasedKeyboardDidMoveBlock = frameBasedActionHandler
        }
        if let constraintBasedActionHandler = constraintBasedActionHandler {
            constraintBasedKeyboardDidMoveBlock = constraintBasedActionHandler
        }
        
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
    
    @objc fileprivate func responderDidBecomeActive(_ notification: Notification) {
        
        keyboardActiveInput = notification.object as? UIResponder
        if keyboardActiveInput?.inputAccessoryView == nil {
            
            let textField = keyboardActiveInput as! UITextField
            if textField.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                let nullView: UIView = UIView(frame: CGRect.zero)
                nullView.backgroundColor = .clear
                textField.inputAccessoryView = nullView
            }
            keyboardActiveInput = textField as UIResponder
            inputKeyboardDidShow()
        }
    }
    
    // MARK: - Keyboard Notifications
    
    @objc fileprivate func inputKeyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }

        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = .easeInOut
        if let curveIntValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let curve = UIViewAnimationCurve(rawValue: curveIntValue << 16) {
            keyboardTransitionAnimationCurve = curve
        }

        keyboardActiveView?.isHidden = false
        keyboardOpened = true
        
        let keyboardEndFrameView = convert(keyboardEndFrameWindow, from: nil)
        
        let constraintBasedKeyboardDidMoveBlockCalled = (constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, true, false)
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
        }) { _ in
            if self.panning {

                // remove before recognizer
                if let panRecognizer = self.keyboardPanRecognizer {
                    self.removeGestureRecognizer(panRecognizer)
                }
                self.keyboardPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(UIView.panGestureDidChange(_:)))
                self.keyboardPanRecognizer?.delegate = self
                self.keyboardPanRecognizer?.cancelsTouchesInView = false
                
                guard let panGesture = self.keyboardPanRecognizer else { return }
                self.addGestureRecognizer(panGesture)
            }
        }
    }
    
    @objc fileprivate func inputKeyboardDidShow() {
        keyboardActiveView = findInputSetHostView()
        keyboardActiveView?.isHidden = false
        
        if keyboardActiveView == nil {
            keyboardActiveInput = recursiveFindFirstResponder(self)
            keyboardActiveView = findInputSetHostView()
            keyboardActiveView?.isHidden = false
        }
        
        if !keyboardFrameObserved {
            keyboardActiveView?.addObserver(self, forKeyPath: frameKeyPath, options: .new, context: nil)
            keyboardFrameObserved = true
        }
    }
    
    @objc fileprivate func inputKeyboardWillChangeFrame(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }
        
        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = .easeInOut
        if let curveIntValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let curve = UIViewAnimationCurve(rawValue: curveIntValue << 16) {
            keyboardTransitionAnimationCurve = curve
        }
        
        let keyboardEndFrameView = convert(keyboardEndFrameWindow, from: nil)
        
        let constraintBasedKeyboardDidMoveBlockCalled = (constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, false)
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
    
    @objc fileprivate func inputKeyboardDidChangeFrame() {
        // Nothing to see here
    }
    
    @objc fileprivate func inputKeyboardWillHide(_ notification: Notification) {
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        
        guard let keyboardEndFrameWindow: CGRect = ((userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) else { return }
        
        guard let keyboardTransitionDuration: Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        var keyboardTransitionAnimationCurve: UIViewAnimationCurve = .easeInOut
        if let curveIntValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let curve = UIViewAnimationCurve(rawValue: curveIntValue << 16) {
            keyboardTransitionAnimationCurve = curve
        }
        
        var keyboardEndFrameView = convert(keyboardEndFrameWindow, from: nil)
        keyboardEndFrameView.origin.y -= safeAreaBottomInset
        
        let constraintBasedKeyboardDidMoveBlockCalled = (constraintBasedKeyboardDidMoveBlock != nil && !keyboardEndFrameView.isNull)
        
        if constraintBasedKeyboardDidMoveBlockCalled {
            constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, true)
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
        }) { _ in
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
    
    @objc fileprivate func inputKeyboardDidHide() {
        
        keyboardActiveView?.isHidden = false
        keyboardActiveView?.isUserInteractionEnabled = true
        keyboardActiveView = nil
        keyboardActiveInput = nil
        keyboardOpened = false
    }

    fileprivate func hideKeyboard(isKeyboardViewHidden: Bool) {

        if keyboardActiveView != nil {
            keyboardActiveView?.isHidden = isKeyboardViewHidden
            keyboardActiveView?.isUserInteractionEnabled = false
            keyboardActiveInput?.resignFirstResponder()
        }
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        if keyPath == frameKeyPath && object as? UIView == keyboardActiveView {
            guard let keyboardEndFrameWindow = (object as? UIView)?.frame else { return }
            guard var keyboardEndFrameView = keyboardActiveView?.frame else { return }
            keyboardEndFrameView.origin.y = keyboardEndFrameWindow.origin.y
            if keyboardEndFrameView.origin.y > UIScreen.main.bounds.height - safeAreaBottomInset {
                keyboardEndFrameView.origin.y = UIScreen.main.bounds.height - safeAreaBottomInset
            }
            
            if keyboardEndFrameView.equalTo(previousKeyboardRect) {
                return
            }
            
            guard let activityView = keyboardActiveView else { return }
            
            if !activityView.isHidden && !keyboardEndFrameView.isNull {
                
                if frameBasedKeyboardDidMoveBlock != nil {
                    frameBasedKeyboardDidMoveBlock?(keyboardEndFrameView, false, false)
                }
                
                if constraintBasedKeyboardDidMoveBlock != nil {
                    constraintBasedKeyboardDidMoveBlock?(keyboardEndFrameWindow, false, false)
                    layoutIfNeeded()
                }
            }
            
            previousKeyboardRect = keyboardEndFrameView
        }
    }
    
    // MARK: - Touches Management
    
    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == keyboardPanRecognizer || otherGestureRecognizer == keyboardPanRecognizer {
            return true
        }
        else {
            return false
        }
    }
    
    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer == keyboardPanRecognizer {
            
            guard let touchView = touch.view else { return true }
            
            return (!touchView.isFirstResponder || (isKind(of: UITextView.self) && isEqual(touchView)))
        }
        else {
            return true
        }
    }
    
    @objc fileprivate func panGestureDidChange(_ gesture: UIPanGestureRecognizer) {
        
        if keyboardActiveView == nil || keyboardActiveInput == nil || keyboardActiveView?.isHidden ?? false {
            keyboardActiveInput = recursiveFindFirstResponder(self)
            keyboardActiveView = findInputSetHostView()
            keyboardActiveView?.isHidden = false
        }
        else {
            keyboardActiveView?.isHidden = false
        }
        
        guard let activityView = keyboardActiveView else { return }
        guard let activityViewSuperView = activityView.superview else { return }
        
        let keyboardViewHeight: CGFloat = activityView.bounds.size.height
        let keyboardWindowHeight: CGFloat = activityViewSuperView.bounds.size.height
        let touchLocationInKeyboardWindow = gesture.location(in: activityView.superview)
        
        if touchLocationInKeyboardWindow.y > keyboardWindowHeight - keyboardViewHeight - keyboardTriggerOffset {
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
            newKeyboardViewFrame.origin.y = touchLocationInKeyboardWindow.y + keyboardTriggerOffset
            newKeyboardViewFrame.origin.y = min(newKeyboardViewFrame.origin.y, keyboardWindowHeight)
            newKeyboardViewFrame.origin.y = max(newKeyboardViewFrame.origin.y, keyboardWindowHeight - keyboardViewHeight)
            if (keyboardActiveInput?.isFirstResponder ?? false) && newKeyboardViewFrame.origin.y > UIScreen.main.bounds.height - safeAreaBottomInset {
                newKeyboardViewFrame.origin.y = UIScreen.main.bounds.height - safeAreaBottomInset
            }

            if newKeyboardViewFrame.origin.y != keyboardActiveView?.frame.origin.y {
                
                UIView.animate(withDuration: 0,
                               delay: 0,
                               options: .beginFromCurrentState,
                               animations: {
                                
                                activityView.frame = newKeyboardViewFrame
                    }, completion: nil)
            }
            
            break
            
        case .ended, .cancelled:
            
            let thresholdHeight = keyboardWindowHeight - keyboardViewHeight - keyboardTriggerOffset + 44
            let velocity = gesture.velocity(in: keyboardActiveView)
            var shouldRecede = Bool()
            
            if touchLocationInKeyboardWindow.y < thresholdHeight || velocity.y < 0 {
                shouldRecede = false
            }
            else {
                shouldRecede = true
            }
            
            var newKeyboardViewFrame = activityView.frame
            newKeyboardViewFrame.origin.y = !shouldRecede ? keyboardWindowHeight - keyboardViewHeight: keyboardWindowHeight
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseOut, .beginFromCurrentState],
                           animations: {
                            activityView.frame = newKeyboardViewFrame
                }, completion: { _ in
                    
                    activityView.isUserInteractionEnabled = !shouldRecede
                    
                    if shouldRecede {
                        self.hideKeyboard(isKeyboardViewHidden: true)
                    }
            })
            gesture.maximumNumberOfTouches = LONG_MAX

            break
        default:
            break
        }
    }
    
    // MARK: - Internal Methods
    
    fileprivate func recursiveFindFirstResponder(_ view: UIView) -> UIView? {
        
        if view.isFirstResponder {
            return view
        }
        var found: UIView? = nil
        for v in view.subviews {
            
            found = recursiveFindFirstResponder(v)
            if found != nil {
                break
            }
        }
        return found
    }
    
    fileprivate func findInputSetHostView() -> UIView? {
        
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
            return keyboardActiveInput?.inputAccessoryView?.superview
        }
        
        return nil
    }
    
    @objc fileprivate func swizzled_addSubview(_ subView: UIView) {
        
        if subView.inputAccessoryView == nil  {
            
            if subView.isKind(of: UITextField.self) {
                let textField = subView as! UITextField
                if textField.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                    let nullView: UIView = UIView(frame: .zero)
                    nullView.backgroundColor = .clear
                    textField.inputAccessoryView = nullView
                }
            }
            else if subView.isKind(of: UITextView.self) {
                let textView = subView as! UITextView
                if textView.responds(to: #selector(getter: UIResponder.inputAccessoryView)) {
                    let nullView: UIView = UIView(frame: .zero)
                    nullView.backgroundColor = .clear
                    textView.inputAccessoryView = nullView
                }
            }
        }
        swizzled_addSubview(subView)
    }
}

extension UIApplication {
    private static let runOnce: Void = {
        UIView.initializeControl()
    }()

    override open var next: UIResponder? {
        // Called before applicationDidFinishLaunching
        UIApplication.runOnce
        return super.next
    }
}
