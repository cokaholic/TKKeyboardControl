#
# Be sure to run `pod lib lint TKKeyboardControl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TKKeyboardControl"
  s.version          = "1.0.3"
  s.summary          = "TKKeyboardControl adds keyboard awareness and scrolling dismissal (a.k.a. iMessages app) to any view with only 1 line of code for Swift."

  s.homepage         = "https://github.com/cztatsumi-keisuke"

  s.license          = 'MIT'
  s.author           = { "cztatsumi-keisuke" => "nietzsche.god.is.dead@gmail.com" }
  s.source           = { :git => "https://github.com/cztatsumi-keisuke/TKKeyboardControl.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/TK_u_nya'

  s.platform = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'TKKeyboardControl/Classes/*.{swift}'
  #s.resource_bundles = {
  #  'TKKeyboardControl' => ['TKKeyboardControl/Assets/*.png']
  #}

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
end
