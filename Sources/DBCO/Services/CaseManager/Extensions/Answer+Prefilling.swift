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
        var sameHouseholdRisk: Bool?
        var distanceRisk: Answer.Value.Distance?
        var physicalContactRisk: Bool?
        var sameRoomRisk: Bool?
        
        ClassificationHelper.setValues(for: contactCategory, sameHouseholdRisk: &sameHouseholdRisk, distanceRisk: &distanceRisk, physicalContactRisk: &physicalContactRisk, sameRoomRisk: &sameRoomRisk)
        
        return .classificationDetails(sameHouseholdRisk: sameHouseholdRisk,
                                      distanceRisk: distanceRisk,
                                      physicalContactRisk: physicalContactRisk,
                                      sameRoomRisk: sameRoomRisk)
    }
}

extension Answer.Value {
    /// Create a prefilled .contactDetails case.
    /// - parameter contact: The CNContact to be used
    static func contactDetails(contact: CNContact) -> Self {
        let email = contact.contactEmailAddresses.count == 1 ? contact.contactEmailAddresses.first?.value : nil
        let phoneNumber = contact.contactPhoneNumbers.count == 1 ? contact.contactPhoneNumbers.first?.value : nil
        
        return .contactDetails(firstName: contact.contactFirstName.value,
                               lastName: contact.contactLastName.value,
                               email: email,
                               phoneNumber: phoneNumber)
    }
}
