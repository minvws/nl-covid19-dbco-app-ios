/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation


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
    }
    
    static func classification(for livedTogetherRisk: Bool?,
                        durationRisk: Bool?,
                        distanceRisk: Bool?,
                        otherRisk: Bool?) -> Result {
        
        switch livedTogetherRisk {
        case .some(true):
            return .success(.category1)
        case .some(false):
            switch durationRisk {
            case .some(true):
                switch distanceRisk {
                case .some(true):
                    return .success(.category2a)
                case .some(false):
                    return .success(.category3)
                case .none:
                    return .needsAssessmentFor(.distance)
                }
            case .some(false):
                switch distanceRisk {
                case .some(true):
                    switch otherRisk {
                    case .some(true):
                        return .success(.category2b)
                    case .some(false):
                        return .success(.other)
                    case .none:
                        return .needsAssessmentFor(.other)
                    }
                case .some(false):
                    return .success(.other)
                case .none:
                    return .needsAssessmentFor(.distance)
                }
            case .none:
                return .needsAssessmentFor(.duration)
            }
        case .none:
            return .needsAssessmentFor(.livedTogether)
        }
    }
    
    static func classifiedRisks(for category: Task.Contact.Category) -> [Risk] {
        switch category {
        case .category1:
            return [.livedTogether]
        case .category2a:
            return [.livedTogether, .duration, .distance]
        case .category2b:
            return [.livedTogether, .duration, .distance, .other]
        case .category3:
            return [.livedTogether, .duration, .distance]
        case .other:
            return [.livedTogether, .duration, .distance]
        }
    }
    
    static func classifiedRisks(forUnassessedRisk risk: Risk) -> [Risk] {
        switch risk {
        case .livedTogether:
            return []
        case .duration:
            return [.livedTogether]
        case .distance:
            return [.livedTogether, .duration]
        case .other:
            return [.livedTogether, .duration, .distance]
        }
    }
    
}
