#
# Be sure to run `pod lib lint TKKeyboardControl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TKKeyboardControl"
  s.version          = "2.0.0"
  s.summary          = "TKKeyboardControl adds keyboard awareness and scrolling dismissal to any view with only 1 line of code for Swift4 and it supports SafeArea."

  s.homepage         = "https://github.com/cokaholic"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Keisuke Tatsumi" => "nietzsche.god.is.dead@gmail.com" }
  s.source           = { :git => "https://github.com/cokaholic/TKKeyboardControl.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/TK_u_nya'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TKKeyboardControl/Classes/*.{swift}'
end
