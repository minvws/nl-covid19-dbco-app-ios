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
    
    @UserDefaults(key: "ConfigManager.cachedConfig", defaultValue: nil)
    private var cachedConfig: AppConfiguration? // swiftlint:disable:this let_var_whitespace
    
    var featureFlags: FeatureFlags = .empty
    var symptoms: [Symptom] = []
    var supportedZipCodeRanges: [ZipRange] = []
    
    func update(completion: @escaping (ConfigUpdateResult) -> Void) {
        Services.networkManager.getAppConfiguration { result in
            switch result {
            case .success(let configuration):
                self.handleConfiguration(configuration, completion: completion)
            case .failure:
                self.handleFailure(completion: completion)
            }
        }
    }
    
    private func handleFailure(completion: @escaping (ConfigUpdateResult) -> Void) {
        let oneWeekInterval: TimeInterval = 60 * 60 * 24 * 7
        
        guard let cachedConfig = cachedConfig else { return completion(.updateFailed) }
        
        logDebug("Cached configuration age: \(cachedConfig.fetchDate.timeIntervalSinceNow)")
        
        guard cachedConfig.fetchDate.timeIntervalSinceNow > -oneWeekInterval else { return completion(.updateFailed) }
        
        logDebug("Falling back to cached configuration")
        handleConfiguration(cachedConfig, completion: completion)
    }
    
    private func handleConfiguration(_ configuration: AppConfiguration, completion: @escaping (ConfigUpdateResult) -> Void) {
        let requiredVersion = fullVersionString(for: configuration.minimumVersion)
        let currentVersion = fullVersionString(for: appVersion)
        
        logDebug("Updated feature flags: \(configuration.featureFlags)")
        featureFlags = configuration.featureFlags
        symptoms = configuration.symptoms
        
        supportedZipCodeRanges = configuration.supportedZipCodeRanges
        
        cachedConfig = configuration
        
        if requiredVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
            completion(.updateRequired(configuration))
        } else {
            completion(.noActionNeeded)
        }
    }
    
    private func fullVersionString(for version: String) -> String {
        var components = version.split(separator: ".")
        let missingComponents = max(0, 3 - components.count)
        components.append(contentsOf: Array(repeating: "0", count: missingComponents))
        
        return components.joined(separator: ".")
    }
}
