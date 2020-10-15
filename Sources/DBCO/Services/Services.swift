/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class Services {
    private static var networkManagingType: NetworkManaging.Type = NetworkManager.self
    
    /// Override the NetworkManaging type that will be instantiated
    static func use(_ networkManager: NetworkManager.Type) {
        networkManagingType = networkManager
    }
    
    static private(set) var network: NetworkManaging = networkManagingType.init(configuration: .test)
}
