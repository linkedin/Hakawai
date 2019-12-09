Pod::Spec.new do |s|

  s.name         = "Hakawai"
  s.version      = "7.1.6"
  s.summary      = "Hakawai aims to be a more powerful UITextView."
  s.description  = <<-DESC
                   Hakawai is a subclass of UITextView that exposes a number of convenience APIs, and supports further extension via 'plug-ins'. Hakawai ships with an easy-to-use, powerful, and customizable plug-in allowing users to create social media 'mentions'-style annotations.
                   DESC

  s.subspec "Core" do |core|
    core.source_files = "Hakawai/{Core,ChooserView}/**/*.{h,m}"
  end

  s.subspec "Mentions" do |mentions|
    mentions.source_files = "Hakawai/Mentions/**/*.{h,m}"
    mentions.dependency "Hakawai/Core"
  end

  s.homepage     = "https://github.com/linkedin/Hakawai/"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.authors      = "Austin Zheng"
  s.platform = :ios, "10.0"
  s.source       = { :git => "https://github.com/linkedin/Hakawai.git", :tag => "7.1.6" }
  s.framework  = "UIKit"
  s.requires_arc = true
end
