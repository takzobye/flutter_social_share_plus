Pod::Spec.new do |s|
  s.name             = 'flutter_social_share_plus'
  s.version          = '0.1.0'
  s.summary          = 'Share content to Instagram and Facebook from Flutter.'
  s.description      = <<-DESC
Flutter plugin for sharing content to Instagram and Facebook.
Supports feed posts, stories, reels, and direct messages.
                       DESC
  s.homepage         = 'https://github.com/takzobye/flutter_social_share_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'takzobye' => 'takzobye@dev.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_social_share_plus/Sources/flutter_social_share_plus/**/*.swift'
  s.resource_bundles = {
    'flutter_social_share_plus_privacy' => ['flutter_social_share_plus/Sources/flutter_social_share_plus/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit', '~> 17.0'
  s.dependency 'FBSDKShareKit', '~> 17.0'
  s.platform         = :ios, '15.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.9'
end
