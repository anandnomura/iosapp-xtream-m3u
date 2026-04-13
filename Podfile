source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '17.0'
use_frameworks!
inhibit_all_warnings!

target 'OneXtreamM3U' do
  pod 'MobileVLCKit'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGNING_IDENTITY'] = ''
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      config.build_settings['DEVELOPMENT_TEAM'] = ''
    end
  end
end
