Pod::Spec.new do |s|
  s.name         = "RMOverlayController"
  s.version      = "0.1"
  s.summary      = "Overlay menu controller"
  s.description  = "Overlay menu controller"
  s.homepage     = "https://github.com/intonarumori/RMOverlayController"
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { "Daniel Langh" => "intonarumori@gmail.com" }
  s.source       = { :git => "https://github.com/intonarumori/RMOverlayController", :tag => "v0.1" }
  s.platform     = :ios, '7.0'

  s.source_files = 'RMOverlayController/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = [ "UIKit" ]
end