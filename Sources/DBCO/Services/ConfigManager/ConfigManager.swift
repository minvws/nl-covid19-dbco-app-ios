/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class ConfigManager: ConfigManaging {
    required init() {}
    
    // swiftlint:disable:next force_cast
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    func checkUpdateRequired(completion: @escaping (UpdateState) -> Void) {
        func fullVersionString(_ version: String) -> String {
            var components = version.split(separator: ".")
            let missingComponents = max(0, 3 - components.count)
            components.append(contentsOf: Array(repeating: "0", count: missingComponents))
            
            return components.joined(separator: ".")
        }
        
        Services.networkManager.getAppConfiguration { [appVersion] result in
            switch result {
            case .success(let configuration):
                let requiredVersion = fullVersionString(configuration.minimumVersion)
                let currentVersion = fullVersionString(appVersion)
                
                if requiredVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    completion(.updateRequired(configuration))
                } else {
                    completion(.noActionNeeded)
                }
            case .failure:
                completion(.noActionNeeded)
            }
        }
    }
}
