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
        case .classificationDetails(let category):
            switch category {
            case .some:
                return [true]
            case .none:
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
    
    /// A boolean indicating whether or not the asnwer is essential for a complete and usable questionnaire result.
    /// - Tag: Answer.isEssential
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
    
    var isCompleted: Bool {
        return progressElements.allSatisfy { $0 }
    }
    
}

extension QuestionnaireResult {
    
    /// An array of booleans indicating the progress of completing the questionnaire
    /// Used for calculating the [task's status](x-source-tag://Task.status)
    var progressElements: [Bool] {
        return answers.flatMap(\.progressElements)
    }
    
    /// A boolean indicating whether or not all the essential answers are completed
    /// Used for calculating the [task's status](x-source-tag://Task.status)
    ///
    /// # See also:
    /// [Answer.isEssential](x-source-tag://Answer.isEssential)
    var hasAllEssentialAnswers: Bool {
        return answers.filter(\.isEssential).allSatisfy {
            $0.progressElements.allSatisfy { $0 }
        }
    }
    
}
