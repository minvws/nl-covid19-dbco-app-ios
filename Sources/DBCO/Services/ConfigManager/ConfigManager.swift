/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class ConfigManager: ConfigManaging {
    required init() {}
    
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    func checkUpdateRequired(completion: @escaping (UpdateState) -> Void) {
        Services.networkManager.getAppConfiguration { [appVersion] result in
            switch result {
            case .success(let configuration):
                if configuration.minimumVersion.compare(appVersion, options: .numeric) == .orderedDescending {
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
