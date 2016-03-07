Pod::Spec.new do |s|
  s.name         = "IQAudioRecorderController"
  s.version      = "1.1.0"
  s.summary      = "A drop-in universal library allows to record audio within the app with a nice User Interface."
  s.homepage     = "https://github.com/hackiftekhar/IQAudioRecorderController"
  s.license      = 'MIT'
  s.author       = { "Iftekhar Qurashi" => "hack.iftekhar@gmail.com" }
  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/hackiftekhar/IQAudioRecorderController.git", :tag => "v1.1.0" }
  s.source_files = 'IQAudioRecorderController/**/*.{h,m}'
  s.frameworks = 'UIKit', 'AVFoundation'
  s.dependency 'SCSiriWaveformView', 'FDWaveformView'
  s.resources    = "IQAudioRecorderController/Resources/*.{png}"
  s.requires_arc = true
end