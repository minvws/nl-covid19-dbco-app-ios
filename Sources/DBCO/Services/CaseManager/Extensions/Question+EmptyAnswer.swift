/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Question {
    
    var emptyAnswer: Answer {
        let value: Answer.Value = {
            switch questionType {
            case .classificationDetails:
                return .classificationDetails(sameHouseholdRisk: nil, distanceRisk: nil, physicalContactRisk: nil, sameRoomRisk: nil)
            case .contactDetails:
                return .contactDetails(firstName: nil, lastName: nil, email: nil, phoneNumber: nil)
            case .contactDetailsFull:
                return .contactDetailsFull(firstName: nil, lastName: nil, email: nil, phoneNumber: nil)
            case .date:
                return .date(nil)
            case .open:
                return .open(nil)
            case .multipleChoice:
                return .multipleChoice(nil)
            case .lastExposureDate:
                return .lastExposureDate(nil)
            }
        }()
        return Answer(uuid: UUID(), questionUuid: uuid, lastModified: Date(), value: value)
    }
    
}
