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
/// The backend only concerns itself with categories `1`, `2a`, `2b` and `3`.
/// The app also defines an additinal category `other` to handle the case where the contact (task) doesn't need to be informed about exposure to the index (patient).
///
/// # See also
/// [Task.Contact.Category](x-source-tag://Task.Contact.Category)
/// - Tag: ClassificationHelper
struct ClassificationHelper {
    
    enum Risk {
        /// The risk contacts have when living in the same household as the index (patient) or when having been near each other for longer than 12 hours.
        case livedTogether
        
        /// The risk contacts have when having near the index for 15min
        case duration
        
        /// The risk contacts have when having been closer than 1,5m to the index
        case distance
        
        /// The risk contacts have when having any of the following occured: Sneezing, cuddling, kissing or other physical contact
        case other
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

    private static func classification(for livedTogetherRisk: Bool?,
                               durationRisk: Bool?,
                               distanceRisk: Bool?,
                               otherRisk: Bool?) -> (result: Result, visibleRisks: [Risk]) {
        
        switch livedTogetherRisk {
        case .some(true):
            return (.success(.category1), [.livedTogether])
        case .some(false):
            switch durationRisk {
            case .some(true):
                switch distanceRisk {
                case .some(true):
                    return (.success(.category2a), [.livedTogether, .duration, .distance])
                case .some(false):
                    return (.success(.category3), [.livedTogether, .duration, .distance])
                case .none:
                    return (.needsAssessmentFor(.distance), [.livedTogether, .duration, .distance])
                }
            case .some(false):
                switch distanceRisk {
                case .some(true):
                    switch otherRisk {
                    case .some(true):
                        return (.success(.category2b), [.livedTogether, .duration, .distance, .other])
                    case .some(false):
                        return (.success(.other), [.livedTogether, .duration, .distance, .other])
                    case .none:
                        return (.needsAssessmentFor(.other), [.livedTogether, .duration, .distance, .other])
                    }
                case .some(false):
                    return (.success(.other), [.livedTogether, .duration, .distance])
                case .none:
                    return (.needsAssessmentFor(.distance), [.livedTogether, .duration, .distance])
                }
            case .none:
                return (.needsAssessmentFor(.duration), [.livedTogether, .duration])
            }
        case .none:
            return (.needsAssessmentFor(.livedTogether), [.livedTogether])
        }
    }
    
    /// Returns the classification or unassessed risk for the supplied parameters
    ///
    /// - parameter livedTogetherRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter durationRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter distanceRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter otherRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func classificationResult(for livedTogetherRisk: Bool?,
                                     durationRisk: Bool?,
                                     distanceRisk: Bool?,
                                     otherRisk: Bool?) -> Result {
        
        classification(for: livedTogetherRisk,
                       durationRisk: durationRisk,
                       distanceRisk: distanceRisk,
                       otherRisk: otherRisk)
            .result
    }
    
    /// Returns the risks that should be displayed/questioned in the UI for the supplied parameters
    ///
    /// - parameter livedTogetherRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter durationRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter distanceRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter otherRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func visibleRisks(for livedTogetherRisk: Bool?,
                             durationRisk: Bool?,
                             distanceRisk: Bool?,
                             otherRisk: Bool?) -> [Risk] {
        
        classification(for: livedTogetherRisk,
                       durationRisk: durationRisk,
                       distanceRisk: distanceRisk,
                       otherRisk: otherRisk)
            .visibleRisks
    }
    
    /// Set the appropriate risk values for the supplied category
    ///
    /// - parameter category: The category for which the risk values should be set
    /// - parameter livedTogetherRisk: Optional Bool.
    /// - parameter durationRisk: Optional Bool.
    /// - parameter distanceRisk: Optional Bool.
    /// - parameter otherRisk: Optional Bool.
    static func setValues(for category: Task.Contact.Category,
                          livedTogetherRisk: inout Bool?,
                          durationRisk: inout Bool?,
                          distanceRisk: inout Bool?,
                          otherRisk: inout Bool?) {
        switch category {
        case .category1:
            livedTogetherRisk = true
            durationRisk = nil
            distanceRisk = nil
            otherRisk = nil
        case .category2a:
            livedTogetherRisk = false
            durationRisk = true
            distanceRisk = true
            otherRisk = nil
        case .category2b:
            livedTogetherRisk = false
            durationRisk = false
            distanceRisk = true
            otherRisk = true
        case .category3:
            livedTogetherRisk = false
            durationRisk = true
            distanceRisk = false
            otherRisk = nil
        case .other:
            livedTogetherRisk = false
            durationRisk = false
            distanceRisk = false
            otherRisk = false
        }
    }
    
}
