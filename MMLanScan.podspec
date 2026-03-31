Pod::Spec.new do |s|
  s.name             = 'MMLanScan'
  s.version          = '2.2.1'
  s.summary          = 'MMLanScan is an open source project for iOS that helps you scan your network and shows the available devices.'
  
  s.description  = <<-DESC
  MMLanScan is an open source project for iOS that helps you scan your network and shows the available devices and their MAC Address, hostname and Brand name. For those updating from 2.1.2 please note that "Device" class has been renamed to "MMDevice".

  Features
+ Fixed use-after-free crash in SimplePing didFailWithError: by replacing performSelector retain hack with __strong local reference
+ Fixed CFSocket use-after-free crash by adding proper CFBridgingRetain/CFBridgingRelease callbacks to CFSocketContext
+ Changed SimplePing delegate property from assign to weak to prevent dangling pointer crashes
+ Added reentrancy guard in PingOperation to prevent double-completion race conditions
+ Added safety timeout (5s) to PingOperation to prevent hung operations when delegate callbacks are silently dropped
+ Fixed build error on newer Xcode SDKs where check_compile_time macro is no longer defined in AssertMacros.h
                   DESC

  s.homepage         = 'https://github.com/mavris/MMLanScan'
  s.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author           = { 'Michael Mavris' => 'info@miksoft.net' }
  s.source           = { :git => 'https://github.com/mavris/MMLanScan.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.source_files = 'MMLanScan/**/*.{h,m}'
  s.resources        = 'MMLanScan/Data/data.plist'
end
