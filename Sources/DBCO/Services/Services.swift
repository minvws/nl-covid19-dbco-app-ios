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
    
    static private(set) var networkManager: NetworkManaging = networkManagingType.init(configuration: .test)
    static private(set) var caseManager: CaseManaging = caseManagingType.init()
}
