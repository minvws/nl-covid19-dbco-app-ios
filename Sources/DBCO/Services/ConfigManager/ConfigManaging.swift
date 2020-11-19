/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol AppVersionInformation {
    var minimumVersion: String { get }
    var minimumVersionMessage: String? { get }
    var appStoreURL: URL? { get }
}

struct AppConfiguration: AppVersionInformation, Decodable {
    let minimumVersion: String
    let minimumVersionMessage: String?
    let appStoreURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case minimumVersion = "iosMinimumVersion"
        case minimumVersionMessage = "iosMinimumVersionMessage"
        case appStoreURL = "iosAppStoreURL"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        minimumVersion = try container.decode(String.self, forKey: .minimumVersion)
        minimumVersionMessage = try? container.decode(String?.self, forKey: .minimumVersionMessage)
        
        if let appStoreURLString = try? container.decode(String?.self, forKey: .appStoreURL) {
            appStoreURL = URL(string: appStoreURLString)
        } else {
            appStoreURL = nil
        }
    }
}

enum UpdateState {
    case updateRequired(AppVersionInformation)
    case noActionNeeded
}

/// - Tag: ConfigManaging
protocol ConfigManaging {
    init()
    
    var appVersion: String { get }
    
    func checkUpdateRequired(completion: @escaping (UpdateState) -> Void)
}
