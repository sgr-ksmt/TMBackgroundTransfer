Pod::Spec.new do |s|

  s.name         = "TMBackgroundTransfer"
  s.version      = "0.1.0"
  s.summary      = "バックグランドでデータを転送するためのクラス"
  s.homepage     = "https://github.com/timers-inc/TMBackgroundTransfer"
  #s.screenshots	 = ""
  s.license      = { :type => "MIT" }
  s.author       = { "1_am_a_geek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1_am_a_geek"
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/timers-inc/TMBackgroundTransfer.git", :tag => "0.1.0" }
  s.source_files  = ["TMBackgroundTransfer/TMBackgroundTransfer.{h,m}"]

end
