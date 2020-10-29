/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Answer {

    /// A value in 0...1 indicating the progress of completing the answer
    var progress: Double {
        switch value {
        case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
            let classificationResult = ClassificationHelper.classificationResult(for: category1Risk,
                                                                                 category2aRisk: category2aRisk,
                                                                                 category2bRisk: category2bRisk,
                                                                                 category3Risk: category3Risk)
            
            switch classificationResult {
            case .success:
                return 1
            case .needsAssessmentFor:
                return 0
            }
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            let values = [firstName,
                          lastName,
                          email ?? phoneNumber]
            let validValueCount = values
                .compactMap { $0 }
                .count
            
            return Double(validValueCount) / Double(values.count)
        case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
            let values = [firstName,
                          lastName,
                          email ?? phoneNumber]
            let validValueCount = values
                .compactMap { $0 }
                .count
            
            return Double(validValueCount) / Double(values.count)
        case .date(let value):
            return value != nil ? 1 : 0
        case .open(let value):
            return value?.isEmpty == false ? 1 : 0
        case .multipleChoice(let value):
            return value != nil ? 1 : 0
        case .lastExposureDate(let value):
            return value != nil ? 1 : 0
        }
    }
    
}

extension QuestionnaireResult {
    
    /// A value in 0...1 indicating the progress of completing the quesionnaire.
    /// Used for calculating the [task's status](x-source-tag://Task.status)
    var progress: Double {
        answers.reduce(0) { $0 + ($1.progress / Double(answers.count)) }
    }
    
}
