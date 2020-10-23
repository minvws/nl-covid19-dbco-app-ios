/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Contacts

extension Answer.Value {
    /// Create a correct .classificationDetails case for a specific [Task category](x-source-tag://Task.Contact.Category).
    /// Makes use of [ClassificationHelper](x-source-tag://ClassificationHelper)
    /// - parameter contactCategory: The [category](x-source-tag://Task.Contact.Category) to be used
    static func classificationDetails(contactCategory: Task.Contact.Category) -> Self {
        var livedTogetherRisk: Bool?
        var durationRisk: Bool?
        var distanceRisk: Bool?
        var otherRisk: Bool?
        
        ClassificationHelper.setValues(for: contactCategory, livedTogetherRisk: &livedTogetherRisk, durationRisk: &durationRisk, distanceRisk: &distanceRisk, otherRisk: &otherRisk)
        
        return .classificationDetails(livedTogetherRisk: livedTogetherRisk,
                                      durationRisk: durationRisk,
                                      distanceRisk: distanceRisk,
                                      otherRisk: otherRisk)
    }
}

extension Answer.Value {
    /// Create a prefilled .contactDetails case.
    /// - parameter contact: The CNContact to be used
    static func contactDetails(contact: CNContact) -> Self {
        return .contactDetails(firstName: contact.contactFirstName.value,
                               lastName: contact.contactLastName.value,
                               email: contact.contactEmailAddresses.first?.value,
                               phoneNumber: contact.contactPhoneNumbers.first?.value)
    }
}
