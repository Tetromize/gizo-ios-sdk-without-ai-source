Pod::Spec.new do |s|
  s.name             = 'TetromizeSDK'
  s.version          = '1.0.0'
  s.swift_versions   = '5'
  s.summary          = 'A comprehensive SDK for integrating advanced functionalities provided by GIZO in iOS apps.'
  s.description      = <<-DESC
                        GizoSDK offers advanced features and integrations for iOS applications, including Mapbox Maps, Mapbox Navigation, and additional support for Python and NumPy operations within iOS environments. It leverages both binary and source targets to deliver a powerful toolset for developers.
                       DESC
  s.homepage         = 'https://github.com/Tetromize/gizo-ios-sdk-without-ai-source'
  s.license          = { :type => 'MIT', :file => './LICENSE' }
  s.author           = { 'Tetromize' => 'alidonyaie@gmail.com' }
  s.source           = { :git => 'https://github.com/Tetromize/gizo-ios-sdk-without-ai-source.git', :tag => s.version }
  s.ios.deployment_target = '13.0'
  s.source_files     = 'GizoSDK/**/*.{h,swift}'
  s.resources        = 'GizoSDK/**/*.{bundle}'
  s.dependency 'MapboxMaps', '10.12.3'
  s.dependency 'MapboxNavigation', '2.12.0'
  s.dependency 'SnapKit', '5.6.0'
  s.libraries        = 'z', 'bz2', 'sqlite3'
  s.frameworks       = 'CoreML', 'SystemConfiguration'
end
