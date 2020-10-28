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
        case category1
        
        /// The risk contacts have when having been near the index for 15min
        case category2a
        
        /// The risk contacts have when having had physical contact with the index
        case category2b
        
        /// The risk contacts have when having been in the same room as the index for longer than 15 minutes
        case category3
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

    private static func classification(for category1Risk: Bool?,
                               category2aRisk: Bool?,
                               category2bRisk: Bool?,
                               category3Risk: Bool?) -> (result: Result, visibleRisks: [Risk]) {
        
        switch category1Risk {
        case .some(true):
            return (.success(.category1), [.category1])
        case .none:
            return (.needsAssessmentFor(.category1), [.category1])
        case .some(false):
            switch category2aRisk {
            case .some(true):
                return (.success(.category2a), [.category1, .category2a])
            case .none:
                return (.needsAssessmentFor(.category2a), [.category1, .category2a])
            case .some(false):
                switch category2bRisk {
                case .some(true):
                    return (.success(.category2b), [.category1, .category2a, .category2b])
                case .none:
                    return (.needsAssessmentFor(.category2b), [.category1, .category2a, .category2b])
                case .some(false):
                    switch category3Risk {
                    case .some(true):
                        return (.success(.category3), [.category1, .category2a, .category2b, .category3])
                    case .none:
                        return (.needsAssessmentFor(.category3), [.category1, .category2a, .category2b, .category3])
                    case .some(false):
                        return (.success(.other), [.category1, .category2a, .category2b, .category3])
                    }
                }
            }
        }
    }
    
    /// Returns the classification or unassessed risk for the supplied parameters
    ///
    /// - parameter category1Risk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category2aRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category2bRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category3Risk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func classificationResult(for category1Risk: Bool?,
                                     category2aRisk: Bool?,
                                     category2bRisk: Bool?,
                                     category3Risk: Bool?) -> Result {
        
        classification(for: category1Risk,
                       category2aRisk: category2aRisk,
                       category2bRisk: category2bRisk,
                       category3Risk: category3Risk)
            .result
    }
    
    /// Returns the risks that should be displayed/questioned in the UI for the supplied parameters
    ///
    /// - parameter category1Risk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category2aRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category2bRisk: Optional Bool, set to nil if this risk has not been assessed yet.
    /// - parameter category3Risk: Optional Bool, set to nil if this risk has not been assessed yet.
    static func visibleRisks(for category1Risk: Bool?,
                             category2aRisk: Bool?,
                             category2bRisk: Bool?,
                             category3Risk: Bool?) -> [Risk] {
        
        classification(for: category1Risk,
                       category2aRisk: category2aRisk,
                       category2bRisk: category2bRisk,
                       category3Risk: category3Risk)
            .visibleRisks
    }
    
    /// Set the appropriate risk values for the supplied category
    ///
    /// - parameter category: The category for which the risk values should be set
    /// - parameter category1Risk: Optional Bool.
    /// - parameter category2aRisk: Optional Bool.
    /// - parameter category2bRisk: Optional Bool.
    /// - parameter category3Risk: Optional Bool.
    static func setValues(for category: Task.Contact.Category,
                          category1Risk: inout Bool?,
                          category2aRisk: inout Bool?,
                          category2bRisk: inout Bool?,
                          category3Risk: inout Bool?) {
        switch category {
        case .category1:
            category1Risk = true
            category2aRisk = nil
            category2bRisk = nil
            category3Risk = nil
        case .category2a:
            category1Risk = false
            category2aRisk = true
            category2bRisk = nil
            category3Risk = nil
        case .category2b:
            category1Risk = false
            category2aRisk = false
            category2bRisk = true
            category3Risk = nil
        case .category3:
            category1Risk = false
            category2aRisk = false
            category2bRisk = false
            category3Risk = true
        case .other:
            category1Risk = false
            category2aRisk = false
            category2bRisk = false
            category3Risk = false
        }
    }
    
}
