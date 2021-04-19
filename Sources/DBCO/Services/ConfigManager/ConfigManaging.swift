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

struct FeatureFlags: Codable {
    let enableContactCalling: Bool
    let enablePerspectiveSharing: Bool
    let enablePerspectiveCopy: Bool
    let enableSelfBCO: Bool
    
    static var empty: FeatureFlags {
        return FeatureFlags(enableContactCalling: false, enablePerspectiveSharing: false, enablePerspectiveCopy: false, enableSelfBCO: false)
    }
}

struct Symptom: Codable, Equatable {
    let label: String
    let value: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}

struct AppConfiguration: AppVersionInformation, Codable {
    let minimumVersion: String
    let minimumVersionMessage: String?
    let appStoreURL: URL?
    let featureFlags: FeatureFlags
    let symptoms: [Symptom]
    let supportedZipCodeRanges: [ZipRange]
    let fetchDate: Date
    
    enum CodingKeys: String, CodingKey {
        case minimumVersion = "iosMinimumVersion"
        case minimumVersionMessage = "iosMinimumVersionMessage"
        case appStoreURL = "iosAppStoreURL"
        case featureFlags
        case symptoms
        case supportedZipCodeRanges
        case fetchDate
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
        
        featureFlags = try container.decode(FeatureFlags.self, forKey: .featureFlags)
        symptoms = try container.decode([Symptom].self, forKey: .symptoms)
        supportedZipCodeRanges = try container.decode([ZipRange].self, forKey: .supportedZipCodeRanges)
        
        fetchDate = (try container.decodeIfPresent(Date.self, forKey: .fetchDate)) ?? Date()
    }
}

enum ConfigUpdateResult {
    case updateRequired(AppVersionInformation)
    case updateFailed
    case noActionNeeded
}

/// - Tag: ConfigManaging
protocol ConfigManaging {
    init()
    
    var appVersion: String { get }
    var featureFlags: FeatureFlags { get }
    var symptoms: [Symptom] { get }
    var supportedZipCodeRanges: [ZipRange] { get }
    
    func update(completion: @escaping (ConfigUpdateResult) -> Void)
}
