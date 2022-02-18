# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def common_pods
  pod 'web3swift'
end

target 'LedgerLinkV2' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods

  target 'LedgerLinkV2Tests' do
      inherit! :search_paths
      common_pods
  end
end

post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
  end
 end
end