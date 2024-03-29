/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Global container for the different services used in the app
final class Services {
    private static var networkManagingType: NetworkManaging.Type = NetworkManager.self
    private static var caseManagingType: CaseManaging.Type = CaseManager.self
    private static var configManagingType: ConfigManaging.Type = ConfigManager.self
    private static var pairingManagingType: PairingManaging.Type = PairingManager.self
    private static var onboardingManagingType: OnboardingManaging.Type = OnboardingManager.self
    
    /// Override the [NetworkManaging](x-source-tag://NetworkManaging) type that will be instantiated
    /// - parameter networkManager: The type conforming to [NetworkManaging](x-source-tag://NetworkManaging) to be used as the global networkManager
    static func use(_ networkManager: NetworkManaging.Type) {
        networkManagingType = networkManager
    }
    
    /// Override the [CaseManaging](x-source-tag://CaseManaging) type that will be instantiated
    /// - parameter caseManager: The type conforming to [CaseManaging](x-source-tag://CaseManaging) to be used as the global caseManager
    static func use(_ caseManager: CaseManaging.Type) {
        caseManagingType = caseManager
    }
    
    /// Override the [ConfigManaging](x-source-tag://ConfigManaging) type that will be instantiated
    /// - parameter configManager: The type conforming to [ConfigManaging](x-source-tag://ConfigManaging) to be used as the global configManager
    static func use(_ configManager: ConfigManaging.Type) {
        configManagingType = configManager
    }
    
    /// Override the [PairingManaging](x-source-tag://PairingManaging) type that will be instantiated
    /// - parameter pairingManaging: The type conforming to [PairingManaging](x-source-tag://PairingManaging) to be used as the global pairingManager
    static func use(_ pairingManager: PairingManaging.Type) {
        pairingManagingType = pairingManager
    }
    
    /// Override the [OnboardingManaging](x-source-tag://OnboardingManaging) type that will be instantiated
    /// - parameter onboardingManaging: The type conforming to [OnboardingManaging](x-source-tag://OnboardingManaging) to be used as the global onboardingManager
    static func use(_ onboardingManager: OnboardingManaging.Type) {
        onboardingManagingType = onboardingManager
    }
    
    static private(set) var networkManager: NetworkManaging = {
        let networkConfiguration: NetworkConfiguration

        let configurations: [String: NetworkConfiguration] = [
            NetworkConfiguration.test.name.lowercased(): NetworkConfiguration.test,
            NetworkConfiguration.acceptance.name.lowercased(): NetworkConfiguration.acceptance,
            NetworkConfiguration.staging.name.lowercased(): NetworkConfiguration.staging,
            NetworkConfiguration.production.name.lowercased(): NetworkConfiguration.production
        ]

        let fallbackConfiguration = NetworkConfiguration.test

        if let networkConfigurationValue = Bundle.main.infoDictionary?["NETWORK_CONFIGURATION"] as? String {
            networkConfiguration = configurations[networkConfigurationValue.lowercased()] ?? fallbackConfiguration
        } else {
            networkConfiguration = fallbackConfiguration
        }
        
        return networkManagingType.init(configuration: networkConfiguration)
    }()
    static private(set) var caseManager: CaseManaging = caseManagingType.init()
    static private(set) var configManager: ConfigManaging = configManagingType.init()
    static private(set) var pairingManager: PairingManaging = pairingManagingType.init(networkManager: networkManager)
    static private(set) var onboardingManager: OnboardingManaging = onboardingManagingType.init()
}
