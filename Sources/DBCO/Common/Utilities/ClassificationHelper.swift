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
    
    enum Result: Equatable {
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
    
    private typealias ResultRiskPair = (result: Result, visibleRisks: [Risk])
    struct Risks: Equatable {
        var sameHousehold: Bool?
        var distance: Answer.Value.Distance?
        var physicalContact: Bool?
        var sameRoom: Bool?
    }

    private static func evaluate(risks: Risks) -> ResultRiskPair {
        return evaluateSameHouseholdRisk(risks)
    }
    
    private static func evaluateSameHouseholdRisk(_ risks: Risks) -> ResultRiskPair {
        switch risks.sameHousehold {
        case .none:
            return (.needsAssessmentFor(.sameHousehold), [.sameHousehold])
        case .some(true):
            return (.success(.category1), [.sameHousehold])
        case .some(false):
            return evaluateDistanceRisk(risks)
        }
    }
    
    private static func evaluateDistanceRisk(_ risks: Risks) -> ResultRiskPair {
        switch risks.distance {
        case .none:
            return (.needsAssessmentFor(.distance), [.sameHousehold, .distance])
        case .some(.yesMoreThan15min):
            return (.success(.category2a), [.sameHousehold, .distance])
        case .some(.yesLessThan15min):
            return evaluatePhysicalContactRisk(risks)
        case .some(.no):
            return (.success(.other), [.sameHousehold, .distance]) // previously resulted in a call to evaluateSameRoomRisk(_ risks: Risks)
        }
    }
    
    private static func evaluatePhysicalContactRisk(_ risks: Risks) -> ResultRiskPair {
        switch risks.physicalContact {
        case .none:
            return (.needsAssessmentFor(.physicalContact), [.sameHousehold, .distance, .physicalContact])
        case .some(true):
            return (.success(.category2b), [.sameHousehold, .distance, .physicalContact])
        case .some(false):
            return (.success(.other), [.sameHousehold, .distance, .physicalContact])
        }
    }
    
//    NOTE: Currently unused
//    private static func evaluateSameRoomRisk(_ risks: Risks) -> ResultRiskPair {
//        switch risks.sameRoom {
//        case .none:
//            return (.needsAssessmentFor(.sameRoom), [.sameHousehold, .distance, .sameRoom])
//        case .some(true):
//            return (.success(.category3b), [.sameHousehold, .distance, .sameRoom])
//        case .some(false):
//            return (.success(.other), [.sameHousehold, .distance, .sameRoom])
//        }
//    }
    
    /// Returns the classification or unassessed risk for the supplied risks
    ///
    /// - parameter risks: Risks
    static func classificationResult(for risks: Risks) -> Result {
        return evaluate(risks: risks).result
    }
    
    /// Returns the risks that should be displayed/questioned in the UI for the supplied risks
    ///
    /// - parameter risks: Risks
    static func visibleRisks(for risks: Risks) -> [Risk] {
        return evaluate(risks: risks).visibleRisks
    }
    
    /// Set the appropriate risk values for the supplied category
    ///
    /// - parameter risks: Risks
    static func setRisks(for category: Task.Contact.Category, risks: inout Risks) {
        risks.sameHousehold = nil
        risks.distance = nil
        risks.physicalContact = nil
        risks.sameRoom = nil
        
        switch category {
        case .category1:
            risks.sameHousehold = true
        case .category2a:
            risks.sameHousehold = false
            risks.distance = .yesMoreThan15min
        case .category2b:
            risks.sameHousehold = false
            risks.distance = .yesLessThan15min
            risks.physicalContact = true
        case .category3a:
            risks.sameHousehold = false
            risks.distance = .yesLessThan15min
            risks.physicalContact = false
        case .category3b:
            risks.sameHousehold = false
            risks.distance = .no
            risks.sameRoom = true
        case .other:
            risks.sameHousehold = false
            risks.distance = .no
            risks.sameRoom = false
        }
    }
    
}
