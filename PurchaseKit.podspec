
Pod::Spec.new do |s|
  s.name             = "PurchaseKit"
  s.version          = "1.0.1"
  s.summary          = "In-App Purchase Framework"
  s.author           = { "Meniny" => "Meniny@qq.com" }
  s.homepage         = "https://github.com/Meniny/PurchaseKit"
  s.social_media_url = 'https://meniny.cn/'
  s.license          = 'MIT'
  s.description      = <<-DESC
                        PurchaseKit is an In-App Purchase Framework written in Swift.
                        DESC

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.source           = { :git => "https://github.com/Meniny/PurchaseKit.git", :tag => s.version.to_s }
  s.source_files = 'PurchaseKit/Source/*'
  s.public_header_files = 'PurchaseKit/Source/*.h'

  s.ios.frameworks = 'Foundation', 'UIKit', 'StoreKit'
  s.tvos.frameworks = 'Foundation', 'UIKit', 'StoreKit'
  s.osx.frameworks = 'Foundation', 'AppKit', 'StoreKit'

  # s.dependency ""
end
