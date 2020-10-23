/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// - Tag: ClassificatonHelper
struct ClassificationHelper {
    enum Risk {
        case livedTogether
        case duration
        case distance
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
