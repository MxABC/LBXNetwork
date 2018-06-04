Pod::Spec.new do |s|
  s.name         = "LBXNetWork"
  s.version      = "1.0.0"
  s.summary      = "http request,tcp stream"
  s.homepage     = "https://github.com/MxABC/LBXNetWork"

  s.license      = "MIT"
  s.author       = { "lbxia" => "lbxia20091227@foxmail.com" }

  s.source       = { :git => "https://github.com/MxABC/LBXNetWork.git",:tag => s.version }

  s.ios.deployment_target = '7.0'

  s.source_files = 'LBXNetWork/**/*.{m,h}'
  s.public_header_files = 'LBXNetWork/AFNetworkVendor/AFNNetworkRequest.h','LBXNetWork/LBXHttpRequest.h','LBXNetWork/LBXNetWork.h','LBXNetWork/LBXTcpStream/LBXTcpStream.h'
  s.ios.frameworks = 'Foundation', 'UIKit'
  
  s.dependency 'AFNetworking', '~> 3.2.0'
  
  s.dependency 'YYCache', '~> 1.0.4'
  
  s.requires_arc = true

end
