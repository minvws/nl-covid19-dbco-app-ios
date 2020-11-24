/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class ConfigManager: ConfigManaging, Logging {
    let loggingCategory = "ConfigManager"
    
    required init() {}
    
    // swiftlint:disable:next force_cast
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var featureFlags: FeatureFlags = AppConfiguration.Flags(enableContactCalling: false,
                                                            enablePerspectiveSharing: false,
                                                            enablePerspectiveCopy: false)
    
    func update(completion: @escaping (UpdateState, FeatureFlags) -> Void) {
        func fullVersionString(_ version: String) -> String {
            var components = version.split(separator: ".")
            let missingComponents = max(0, 3 - components.count)
            components.append(contentsOf: Array(repeating: "0", count: missingComponents))
            
            return components.joined(separator: ".")
        }
        
        Services.networkManager.getAppConfiguration { result in
            switch result {
            case .success(let configuration):
                let requiredVersion = fullVersionString(configuration.minimumVersion)
                let currentVersion = fullVersionString(self.appVersion)
                
                self.logDebug("Updated feature flags: \(configuration.featureFlags)")
                self.featureFlags = configuration.featureFlags
                
                if requiredVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    completion(.updateRequired(configuration), self.featureFlags)
                } else {
                    completion(.noActionNeeded, self.featureFlags)
                }
            case .failure:
                completion(.noActionNeeded, self.featureFlags)
            }
        }
    }
}
