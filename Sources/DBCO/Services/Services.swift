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
    private static var taskManagingType: TaskManaging.Type = TaskManager.self
    
    /// Override the [NetworkManaging](x-source-tag://NetworkManaging) type that will be instantiated
    /// - parameter networkManager: The type conforming to [NetworkManaging](x-source-tag://NetworkManaging) to be used as the global networkManager
    static func use(_ networkManager: NetworkManaging.Type) {
        networkManagingType = networkManager
    }
    
    /// Override the [TaskManaging](x-source-tag://TaskManaging) type that will be instantiated
    /// - parameter taskManager: The type conforming to [TaskManaging](x-source-tag://TaskManaging) to be used as the global taskManager
    static func use(_ taskManager: TaskManaging.Type) {
        taskManagingType = taskManager
    }
    
    static private(set) var networkManager: NetworkManaging = networkManagingType.init(configuration: .test)
    static private(set) var taskManager: TaskManaging = taskManagingType.init()
}
