# TKKeyboardControl

TKKeyboardControl adds keyboard awareness and scrolling dismissal (like iMessages app) to any view with only 1 line of code **for Swift**.  
This library is inspired by [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl).

[![CI Status](http://img.shields.io/travis/cztatsumi-keisuke/TKKeyboardControl.svg?style=flat)](https://travis-ci.org/cztatsumi-keisuke/TKKeyboardControl)
[![Version](https://img.shields.io/cocoapods/v/TKKeyboardControl.svg?style=flat)](http://cocoapods.org/pods/TKKeyboardControl)
[![License](https://img.shields.io/cocoapods/l/TKKeyboardControl.svg?style=flat)](http://cocoapods.org/pods/TKKeyboardControl)
[![Platform](https://img.shields.io/cocoapods/p/TKKeyboardControl.svg?style=flat)](http://cocoapods.org/pods/TKKeyboardControl)

![keyboard_test](./Images/keyboard_test.gif "keyboard_test")  

## Installation

#### CocoaPods

TKKeyboardControl is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'TKKeyboardControl'
```

#### Manually

Add the [TKKeyboardControl](./TKKeyboardControl) directory to your project.

## Usage

Example project included (./Example)

### Adding pan-to-dismiss (functionality introduced in iMessages)

```swift
self.view.addKeyboardPanningWithFrameBasedActionHandler({ (keyboardFrameInView, opening, closing) in
            
            // Move interface objects accordingly
            // Animation block is handled for you
            
            }, constraintBasedActionHandler: nil)
            // Make sure to call self.view.removeKeyboardControl before the view is released.
            // (It's the balancing call)
```

### Adding keyboard awareness (appearance and disappearance only)

```swift
self.view.addKeyboardNonpanningWithFrameBasedActionHandler({ (keyboardFrameInView, opening, closing) in
            
            // Move interface objects accordingly
            // Animation block is handled for you
            
            }, constraintBasedActionHandler: nil)
            // Make sure to call self.view.removeKeyboardControl before the view is released.
            // (It's the balancing call)
```

### Supporting an above-keyboard input view

The `keyboardTriggerOffset` property allows you to choose at what point the user's finger "engages" the keyboard.

```swift
self.view.keyboardTriggerOffset = 44.0;	// Input view frame height

self.view.addKeyboardPanningWithFrameBasedActionHandler({ (keyboardFrameInView, opening, closing) in
            
            // Move interface objects accordingly
            // Animation block is handled for you
            
            }, constraintBasedActionHandler: nil)
            // Make sure to call self.view.removeKeyboardControl before the view is released.
            // (It's the balancing call)
```

### Dismissing the keyboard (convenience method)

```swift
self.view.hideKeyboard()
```

### Remove the NSNotification observer at the end of a VC's life (convenience method)

```swift
self.view.removeKeyboardControl()
```

## Notes

### Automatic Reference Counting (ARC) support
`TKKeyboardControl` was made with ARC enabled by default.

## Requirements

- Xcode 7.0 or greater
- iOS8.0 or greater

## Author

cztatsumi-keisuke, nietzsche.god.is.dead@gmail.com

## License

TKKeyboardControl is available under the MIT license.

### MIT License

Copyright (c) 2016 Keisuke Tatsumi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
