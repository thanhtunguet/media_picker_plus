#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'media_picker_plus'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin to pick or capture images and videos'
  s.description      = <<-DESC
A Flutter plugin to pick or capture images and videos with quality control options.
                       DESC
  s.homepage         = 'https://github.com/thanhtunguet/media_picker_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'thanhtunguet' => 'ht@thanhtunguet.info' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end