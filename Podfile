# Uncomment the next line to define a global platform for your project
platform :ios, '12.4'

target 'DBCO' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for DBCO
  pod 'Sodium', '~> 0.9.1'
  pod 'CocoaLumberjack/Swift', '~> 3.7.0'
  pod 'IOSSecuritySuite', '~> 1.8.0'

  target 'DBCOTests' do
    inherit! :search_paths
    # Pods for testing
  end

end


target 'DBCOUITests' do
  inherit! :search_paths
  use_frameworks!
  
  # Pods for ui testing
  pod 'CucumberSwift', '~> 3.2.2'
end
