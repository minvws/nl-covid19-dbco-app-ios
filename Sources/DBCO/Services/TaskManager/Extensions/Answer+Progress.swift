/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Answer {

    var progress: Double {
        switch value {
        case .classificationDetails(let livedTogetherRisk, let durationRisk, let distanceRisk, let otherRisk):
            let valueCount = [livedTogetherRisk, durationRisk, distanceRisk, otherRisk]
                .compactMap { $0 }
                .count
            
            return Double(valueCount) / 4
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            let valueCount = [firstName, lastName, email, phoneNumber]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .count
            
            return Double(valueCount) / 4
        case .date(let value):
            return value != nil ? 1 : 0
        case .open(let value):
            return value?.isEmpty == false ? 1 : 0
        case .multipleChoice(let value):
            return value != nil ? 1 : 0
        }
    }
    
}

extension QuestionnaireResult {
    
    var progress: Double {
        answers.reduce(0) { $0 + ($1.progress / Double(answers.count)) }
    }
    
}
