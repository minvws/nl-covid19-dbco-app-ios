/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Used for the required update dialog
///
/// # See also:
/// [AppCoordinator.showRequiredUpdate](x-source-tag://AppCoordinator.showRequiredUpdate)
///
/// - Tag: AppVersionInformation
protocol AppVersionInformation {
    var minimumVersion: String { get }
    var minimumVersionMessage: String? { get }
    var appStoreURL: URL? { get }
}

/// Used to enable or disable parts of the app.
/// - enableContactCalling: Enables the "call [name]" button in the [ContactQuestionnaireViewController's](x-source-tag://ContactQuestionnaireViewController) inform section
/// - enablePerspectiveCopy: Enables the "copy guidelines" button in the [ContactQuestionnaireViewController's](x-source-tag://ContactQuestionnaireViewController) inform section
/// - enableSelfBCO: Enables the self bco flow, allowing users to gather contacts and determining the contagious period without first pairing with the GGD.
///
/// - Tag: FeatureFlags
struct FeatureFlags: Codable {
    /// Enables the "call [name]" button in the [ContactQuestionnaireViewController's](x-source-tag://ContactQuestionnaireViewController) inform section
    let enableContactCalling: Bool
    let enablePerspectiveSharing: Bool
    
    /// Enables the "copy guidelines" button in the [ContactQuestionnaireViewController's](x-source-tag://ContactQuestionnaireViewController) inform section
    let enablePerspectiveCopy: Bool
    
    /// Enables the self bco flow, allowing users to gather contacts and determining the contagious period without first pairing with the GGD.
    let enableSelfBCO: Bool
    
    static var empty: FeatureFlags {
        return FeatureFlags(enableContactCalling: false, enablePerspectiveSharing: false, enablePerspectiveCopy: false, enableSelfBCO: false)
    }
}

/// Used for the list of selectable symptoms in [SelectSymptomsViewController](x-source-tag://SelectSymptomsViewController)
///
/// - Tag: Symptom
struct Symptom: Codable, Equatable {
    let label: String
    let value: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}

/// The configuration object supplied by the api
///
/// - Tag: AppConfiguration
struct AppConfiguration: AppVersionInformation, Decodable {
    let minimumVersion: String
    let minimumVersionMessage: String?
    let appStoreURL: URL?
    let featureFlags: FeatureFlags
    let symptoms: [Symptom]
    let supportedZipCodeRanges: [ZipRange]?
    
    enum CodingKeys: String, CodingKey {
        case minimumVersion = "iosMinimumVersion"
        case minimumVersionMessage = "iosMinimumVersionMessage"
        case appStoreURL = "iosAppStoreURL"
        case featureFlags
        case symptoms
        case supportedZipCodeRanges
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
        supportedZipCodeRanges = try container.decodeIfPresent([ZipRange].self, forKey: .supportedZipCodeRanges)
    }
}

enum UpdateState {
    case updateRequired(AppVersionInformation)
    case noActionNeeded
}

/// Manages fetching the configuration and keeping it up to date.
///
/// # See also:
/// [AppConfiguration](x-source-tag://AppConfiguration),
/// [FeatureFlags](x-source-tag://FeatureFlags),
/// [ConfigManager](x-source-tag://ConfigManager)
///
/// - Tag: ConfigManaging
protocol ConfigManaging {
    init()
    
    /// The current version as a semantic version string
    var appVersion: String { get }
    
    /// The most recent fetched [FeatureFlags](x-source-tag://FeatureFlags)
    var featureFlags: FeatureFlags { get }
    
    /// The most recent fetched [Symptoms](x-source-tag://Symptom)
    var symptoms: [Symptom] { get }
    
    /// The most recent fetched [ZipRanges](x-source-tag://ZipRange) that are part of GGD regions using GGD Contact.
    var supportedZipCodeRanges: [ZipRange] { get }
    
    /// Update the configuration
    func update(completion: @escaping (UpdateState, FeatureFlags) -> Void)
}
