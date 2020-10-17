/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Contacts

extension Answer.Value {
    static func classificationDetails(contactCategory: Task.Contact.Category) -> Self {
        switch contactCategory {
        case .category1:
            return .classificationDetails(livedTogetherRisk: true,
                                          durationRisk: nil,
                                          distanceRisk: nil,
                                          otherRisk: nil)
        case .category2a:
            return .classificationDetails(livedTogetherRisk: false,
                                          durationRisk: true,
                                          distanceRisk: true,
                                          otherRisk: nil)
        case .category2b:
            return .classificationDetails(livedTogetherRisk: false,
                                          durationRisk: false,
                                          distanceRisk: true,
                                          otherRisk: true)
        case .category3:
            return .classificationDetails(livedTogetherRisk: false,
                                          durationRisk: true,
                                          distanceRisk: false,
                                          otherRisk: nil)
        case .other:
            return .classificationDetails(livedTogetherRisk: false,
                                          durationRisk: false,
                                          distanceRisk: false,
                                          otherRisk: nil)
        }
        
        
    }
}

extension Answer.Value {
    static func contactDetails(contact: CNContact) -> Self {
        return .contactDetails(firstName: contact.contactFirstName.value,
                               lastName: contact.contactLastName.value,
                               email: contact.contactEmailAddresses.first?.value,
                               phoneNumber: contact.contactPhoneNumbers.first?.value)
    }
}
