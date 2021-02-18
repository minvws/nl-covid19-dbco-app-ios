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

protocol FeatureFlags {
    var enableContactCalling: Bool { get }
    var enablePerspectiveSharing: Bool { get }
    var enablePerspectiveCopy: Bool { get }
}

struct Symptom: Codable {
    let label: String
    let value: String
}

struct AppConfiguration: AppVersionInformation, Decodable {
    struct Flags: FeatureFlags, Decodable {
        let enableContactCalling: Bool
        let enablePerspectiveSharing: Bool
        let enablePerspectiveCopy: Bool
        
        enum CodingKeys: String, CodingKey {
            case enableContactCalling
            case enablePerspectiveSharing
            case enablePerspectiveCopy
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            enableContactCalling = (try? container.decode(Bool?.self, forKey: .enableContactCalling)) ?? false
            enablePerspectiveSharing = (try? container.decode(Bool?.self, forKey: .enablePerspectiveSharing)) ?? false
            enablePerspectiveCopy = (try? container.decode(Bool?.self, forKey: .enablePerspectiveCopy)) ?? false
        }
        
        init(enableContactCalling: Bool, enablePerspectiveSharing: Bool, enablePerspectiveCopy: Bool) {
            self.enableContactCalling = enableContactCalling
            self.enablePerspectiveSharing = enablePerspectiveSharing
            self.enablePerspectiveCopy = enablePerspectiveCopy
        }
    }
    
    let minimumVersion: String
    let minimumVersionMessage: String?
    let appStoreURL: URL?
    let featureFlags: FeatureFlags
    let symptoms: [Symptom]
    
    enum CodingKeys: String, CodingKey {
        case minimumVersion = "iosMinimumVersion"
        case minimumVersionMessage = "iosMinimumVersionMessage"
        case appStoreURL = "iosAppStoreURL"
        case featureFlags
        case symptoms
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        minimumVersion = try container.decode(String.self, forKey: .minimumVersion)
        minimumVersionMessage = try container.decodeIfPresent(String.self, forKey: .minimumVersionMessage)
        
        if let appStoreURLString = try container.decodeIfPresent(String.self, forKey: .appStoreURL) {
            appStoreURL = URL(string: appStoreURLString)
        } else {
            appStoreURL = nil
        }
        
        featureFlags = (try container.decodeIfPresent(Flags.self, forKey: .featureFlags)) ?? Flags(enableContactCalling: false, enablePerspectiveSharing: false, enablePerspectiveCopy: false)
        symptoms = try container.decode([Symptom].self, forKey: .symptoms)
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
    var featureFlags: FeatureFlags { get }
    var symptoms: [Symptom] { get }
    
    func update(completion: @escaping (UpdateState, FeatureFlags) -> Void)
}
