/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Helper class that converts the four identifiable risks to the contact category if possible.
/// If no category can be determined it returns which risk(s) still needs assesment.
///
/// The backend only concerns itself with categories `1`, `2a`, `2b`, `3a` and `3a`.
/// The app also defines an additinal category `other` to handle the case where the contact (task) doesn't need to be informed about exposure to the index (patient).
///
/// # See also
/// [Task.Contact.Category](x-source-tag://Task.Contact.Category)
/// - Tag: ClassificationHelper
struct ClassificationHelper {
    
    enum Risk {
        /// The risk contacts have when living in the same household as the index (patient) or when having been near each other for longer than 12 hours.
        case sameHousehold
        
        /// The risk contacts have when having been near the index
        case distance
        
        /// The risk contacts have when having had physical contact with the index
        case physicalContact
        
        /// The risk contacts have when having been in the same room as the index for longer than 15 minutes
        case sameRoom
    }
    
    enum Result {
        case success(Task.Contact.Category)
        case needsAssessmentFor(Risk)
        
        var category: Task.Contact.Category? {
            switch self {
            case .success(let category):
                return category
            default:
                return nil
            }
        }
    }

    private static func classification(for sameHouseholdRisk: Bool?,
                                       distanceRisk: Answer.Value.Distance?,
                                       physicalContactRisk: Bool?,
                                       sameRoomRisk: Bool?) -> (result: Result, visibleRisks: [Risk]) {
        
        switch sameHouseholdRisk {
        case .none:
            return (.needsAssessmentFor(.sameHousehold), [.sameHousehold])
        case .some(true):
            return (.success(.category1), [.sameHousehold])
        case .some(false):
            switch distanceRisk {
            case .none:
                return (.needsAssessmentFor(.distance), [.sameHousehold, .distance])
            case .some(.yesMoreThan15min):
                return (.success(.category2a), [.sameHousehold, .distance])
            case .some(.yesLessThan15min):
                switch physicalContactRisk {
                case .none:
                    return (.needsAssessmentFor(.physicalContact), [.sameHousehold, .distance, .physicalContact])
                case .some(true):
                    return (.success(.category2b), [.sameHousehold, .distance, .physicalContact])
                case .some(false):
                    return (.success(.category3a), [.sameHousehold, .distance, .physicalContact])
                }
            case .some(.no):
                switch sameRoomRisk {
                case .none:
                    return (.needsAssessmentFor(.sameRoom), [.sameHousehold, .distance, .sameRoom])
                case .some(true):
                    return (.success(.category3b), [.sameHousehold, .distance, .sameRoom])
                case .some(false):
                    return (.success(.other), [.sameHousehold, .distance, .sameRoom])
                }
            }
        }
    }
    
    /// Returns the classification or unassessed risk for the supplied parameters
    ///
    /// - parameter sameHouseholdRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter distanceRisk: Optional DistanceAnswer, set to nil if this risk has not been assessed yet.
    /// - parameter physicalContactRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter sameRoomRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func classificationResult(for sameHouseholdRisk: Bool?,
                                     distanceRisk: Answer.Value.Distance?,
                                     physicalContactRisk: Bool?,
                                     sameRoomRisk: Bool?) -> Result {
        
        classification(for: sameHouseholdRisk,
                       distanceRisk: distanceRisk,
                       physicalContactRisk: physicalContactRisk,
                       sameRoomRisk: sameRoomRisk)
            .result
    }
    
    /// Returns the risks that should be displayed/questioned in the UI for the supplied parameters
    ///
    /// - parameter sameHouseholdRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter distanceRisk: Optional DistanceAnswer, set to nil if this risk has not been assessed yet.
    /// - parameter physicalContactRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter sameRoomRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func visibleRisks(for sameHouseholdRisk: Bool?,
                             distanceRisk: Answer.Value.Distance?,
                             physicalContactRisk: Bool?,
                             sameRoomRisk: Bool?) -> [Risk] {
        
        classification(for: sameHouseholdRisk,
                       distanceRisk: distanceRisk,
                       physicalContactRisk: physicalContactRisk,
                       sameRoomRisk: sameRoomRisk)
            .visibleRisks
    }
    
    /// Set the appropriate risk values for the supplied category
    ///
    /// - parameter category: The category for which the risk values should be set
    /// - parameter sameHouseholdRisk: Optional Bool.
    /// - parameter distanceRisk: Optional Answer.Value.Distance
    /// - parameter physicalContactRisk: Optional Bool.
    /// - parameter sameRoomRisk: Optional Bool.
    static func setValues(for category: Task.Contact.Category,
                          sameHouseholdRisk: inout Bool?,
                          distanceRisk: inout Answer.Value.Distance?,
                          physicalContactRisk: inout Bool?,
                          sameRoomRisk: inout Bool?) {
        switch category {
        case .category1:
            sameHouseholdRisk = true
            distanceRisk = nil
            physicalContactRisk = nil
            sameRoomRisk = nil
        case .category2a:
            sameHouseholdRisk = false
            distanceRisk = .yesMoreThan15min
            physicalContactRisk = nil
            sameRoomRisk = nil
        case .category2b:
            sameHouseholdRisk = false
            distanceRisk = .yesLessThan15min
            physicalContactRisk = true
            sameRoomRisk = nil
        case .category3a:
            sameHouseholdRisk = false
            distanceRisk = .yesLessThan15min
            physicalContactRisk = false
            sameRoomRisk = nil
        case .category3b:
            sameHouseholdRisk = false
            distanceRisk = .no
            physicalContactRisk = false
            sameRoomRisk = true
        case .other:
            sameHouseholdRisk = false
            distanceRisk = .no
            physicalContactRisk = false
            sameRoomRisk = false
        }
    }
    
}
