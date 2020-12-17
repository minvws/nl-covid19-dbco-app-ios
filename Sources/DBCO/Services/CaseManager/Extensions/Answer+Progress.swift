/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Answer {

    /// An array of booleans indicating the progress of completing (elements of) the answer
    var progressElements: [Bool] {
        switch value {
        case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
            let classificationResult = ClassificationHelper.classificationResult(for: category1Risk,
                                                                                 category2aRisk: category2aRisk,
                                                                                 category2bRisk: category2bRisk,
                                                                                 category3Risk: category3Risk)
            
            switch classificationResult {
            case .success:
                return [true]
            case .needsAssessmentFor:
                return [false]
            }
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            return [firstName != nil,
                    lastName != nil,
                    (email ?? phoneNumber) != nil]
        case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
            return [firstName != nil,
                    lastName != nil,
                    (email ?? phoneNumber) != nil]
        case .date(let value):
            return [value != nil]
        case .open(let value):
            return [value?.isEmpty == false]
        case .multipleChoice(let value):
            return [value != nil]
        case .lastExposureDate(let value):
            return [value != nil]
        }
    }
    
    var isEssential: Bool {
        switch value {
        case .classificationDetails,
             .contactDetails,
             .contactDetailsFull,
             .lastExposureDate:
            return true
        case .date,
             .open,
             .multipleChoice:
            return false
        }
    }
    
}

extension QuestionnaireResult {
    
    /// An array of booleans indicating the progress of completing the questionnaire
    /// Used for calculating the [task's status](x-source-tag://Task.status)
    var progressElements: [Bool] {
        return answers.flatMap(\.progressElements)
    }
    
    var hasAllEssentialAnswers: Bool {
        return answers.filter(\.isEssential).allSatisfy {
            $0.progressElements.allSatisfy { $0 }
        }
    }
    
}
