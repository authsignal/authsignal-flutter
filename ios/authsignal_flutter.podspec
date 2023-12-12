Pod::Spec.new do |s|
  s.name             = 'authsignal_flutter'
  s.version          = '0.0.2'
  s.summary          = 'The Authsignal Flutter SDK.'
  s.description      = 'The Authsignal Flutter SDK.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Authsignal' => 'support@authsignal.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Authsignal', '0.2.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
