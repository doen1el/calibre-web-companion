Pod::Spec.new do |s|
  s.name             = 'vocsy_epub_viewer'
  s.version          = '2.0.0'
  s.summary          = 'A Vocsy epub reader flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/kaushikgodhani/vocsy_epub_viewer.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'dudecoder' => 'kaushik64494@gmail.com' }
  s.source           = { :path => '.' }
  
  
  s.source_files = [
  'Classes/**/*',
  ]

  s.dependency 'Flutter'
  
  s.dependency 'EpubViewerKit', '~> 0.1.3'
  s.ios.deployment_target = '9.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end