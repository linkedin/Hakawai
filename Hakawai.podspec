Pod::Spec.new do |s|

  s.name         = "Hakawai"
  s.version      = "0.0.2"
  s.summary      = "Hakawai is a subclass of UITextView which adds additional functionality, and supports the use of modular plug-ins."
  s.description  = <<-DESC
                   TODO
                   DESC

  s.subspec "Core" do |core|
    core.source_files = "Hakawai/{Core,ChooserView}/**/*.{h,m}"
  end

  s.subspec "Mentions" do |mentions|
    mentions.source_files = "Hakawai/Mentions/**/*.{h,m}"
    mentions.dependency "Hakawai/Core"
  end

  s.homepage     = "http://linkedin.github.io/Hakawai/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = "Austin Zheng"
  s.platform = :ios, "7.1"
  s.source       = { :git => "https://github.com/linkedin/hakawai.git", :tag => "0.0.2" }
  s.framework  = "UIKit"
  s.requires_arc = true
end