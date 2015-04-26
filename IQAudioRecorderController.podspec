Pod::Spec.new do |s|
  s.name         = "IQAudioRecorderController"
  s.version      = "1.0.0"
  s.summary      = "A neat and clean Audio Recorder"
  s.homepage     = "https://github.com/hackiftekhar/IQAudioRecorderController"
  s.license      = 'MIT'
  s.author       = { "Iftekhar Qurashi" => "hack.iftekhar@gmail.com" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/hackiftekhar/IQAudioRecorderController.git", :tag => "v1.0.0" }
  s.source_files = 'Classes', 'IQAudioRecorderController/*.{h,m}'
  s.resources    = "IQAudioRecorderController/Resources/*.{png}"
  s.requires_arc = true
end