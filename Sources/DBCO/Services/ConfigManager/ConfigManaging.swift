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
    
    /// Enables the "copy guidelines" button in the [ContactQuestionnaireViewController's](x-source-tag://ContactQuestionnaireViewController) inform section
    let enablePerspectiveCopy: Bool
    
    /// Enables the self bco flow, allowing users to gather contacts and determining the contagious period without first pairing with the GGD.
    let enableSelfBCO: Bool
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

/// The guidelines that need to be displayed for contact tasks.
///
/// - Tag: Guidelines
struct Guidelines: Codable {
    struct Categories: Codable {
        let category1: String
        let category2: String
        let category3: String
    }
    
    struct RangedCategories: Codable {
        struct Category2: Codable {
            let withinRange: String
            let outsideRange: String
        }

        let category1: String
        let category2: Category2
        let category3: String
    }
    
    let introExposureDateKnown: Categories
    let introExposureDateUnknown: Categories
    let guidelinesExposureDateKnown: RangedCategories
    let guidelinesExposureDateUnknown: Categories
    let referenceNumberItem: String
    let outro: Categories
}

struct AppConfiguration: AppVersionInformation, Codable {
    let minimumVersion: String
    let minimumVersionMessage: String?
    let appStoreURL: URL?
    let featureFlags: FeatureFlags
    let symptoms: [Symptom]
    let guidelines: Guidelines
    let fetchDate: Date
    
    enum CodingKeys: String, CodingKey {
        case minimumVersion = "iosMinimumVersion"
        case minimumVersionMessage = "iosMinimumVersionMessage"
        case appStoreURL = "iosAppStoreURL"
        case featureFlags
        case symptoms
        case guidelines
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
        guidelines = try container.decode(Guidelines.self, forKey: .guidelines)
        
        fetchDate = (try container.decodeIfPresent(Date.self, forKey: .fetchDate)) ?? Date()
    }
}

enum ConfigUpdateResult {
    case updateRequired(AppVersionInformation)
    case updateFailed
    case noActionNeeded
}

/// Manages fetching the configuration and keeping it up to date.
/// Accessing the different properties before `hasValidConfiguration` is `true` is invalid.
///
/// # See also:
/// [AppConfiguration](x-source-tag://AppConfiguration),
/// [FeatureFlags](x-source-tag://FeatureFlags),
/// [ConfigManager](x-source-tag://ConfigManager)
///
/// - Tag: ConfigManaging
protocol ConfigManaging {
    init()
    
    var hasValidConfiguration: Bool { get }
    
    /// The current version as a semantic version string
    var appVersion: String { get }
    
    /// The most recent fetched [FeatureFlags](x-source-tag://FeatureFlags)
    var featureFlags: FeatureFlags { get }
    
    /// The most recent fetched [Symptoms](x-source-tag://Symptom)
    var symptoms: [Symptom] { get }
    
    /// The most recent fetched [Guidelines](x-source-tag://Guidelines).
    var guidelines: Guidelines { get }
    
    func update(completion: @escaping (ConfigUpdateResult) -> Void)
}
