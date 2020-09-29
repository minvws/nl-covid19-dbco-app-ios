/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts

enum ContactType {
    case roommate
    case close
    case general
    case other
}

enum ContactField {
    case firstName
    case lastName
    case phoneNumber
    case email
    case relation
    case birthDate
    case bsn
    case profession
    case companyName
    case notes
    
    var allowsMultiple: Bool {
        switch self {
        case .phoneNumber, .email:
            return true
        default:
            return false
        }
    }
}

struct Contact {
    var type: ContactType
    var values: [(field: ContactField, value: String?, identifier: UUID)]
    
    init(type: ContactType) {
        self.type = type
        self.values = .init()
        
        type.requiredFields.forEach { requiredField in
            if !values.contains(where: { $0.field == requiredField }) {
                values.append((field: requiredField, value: nil, identifier: UUID()))
            }
        }
    }
    
    var fullName: String {
        let nameParts: [String?] = [
            values.first(where: { $0.field == .firstName})?.value,
            values.first(where: { $0.field == .lastName})?.value]
         
        return nameParts
            .compactMap { $0 }
            .joined(separator: " ")
    }
    
    mutating func setValue(_ value: String?, forFieldWithIdentifier identifier: UUID) {
        guard let index = values.firstIndex(where: { $0.identifier == identifier }) else {
            return
        }
        
        values[index].value = value
    }
}

extension ContactType {
    var requiredFields: [ContactField] {
        switch self {
        case .roommate:
            return [.firstName, .lastName, .phoneNumber, .email, .relation, .birthDate, .bsn, .profession]
        case .close:
            return [.firstName, .lastName, .phoneNumber, .email, .relation]
        case .other:
            return [.firstName, .lastName, .phoneNumber, .email]
        case .general:
            return [.firstName, .lastName, .phoneNumber, .email, .companyName, .notes]
        }
    }
}

extension Contact {
    init(type: ContactType, cnContact: CNContact) {
        self.type = type
        self.values = .init()
        
        if cnContact.isKeyAvailable(CNContactGivenNameKey) {
            values.append((field: .firstName, value: cnContact.givenName, identifier: UUID()))
        }
        
        if cnContact.isKeyAvailable(CNContactFamilyNameKey) {
            values.append((field: .lastName, value: cnContact.familyName, identifier: UUID()))
        }
        
        if cnContact.isKeyAvailable(CNContactPhoneNumbersKey) {
            cnContact.phoneNumbers.forEach {
                values.append((field: .phoneNumber, value: $0.value.stringValue, identifier: UUID()))
            }
        }
        
        if cnContact.isKeyAvailable(CNContactEmailAddressesKey) {
            cnContact.emailAddresses.forEach {
                values.append((field: .email, value: $0.value as String, identifier: UUID()))
            }
        }
        
        if cnContact.isKeyAvailable(CNContactBirthdayKey), let date = cnContact.birthday?.date {
            
            values.append((field: .birthDate, value: Self.birthDateFormatter.string(from: date), identifier: UUID()))
        }
        
        // remove non required fields
        values.removeAll { !type.requiredFields.contains($0.field) }
        
        // add values for remaining fields
        type.requiredFields.forEach { requiredField in
            if !values.contains(where: { $0.field == requiredField }) {
                values.append((field: requiredField, value: nil, identifier: UUID()))
            }
        }
    }
}

extension Contact {
    
    static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        
        return formatter
    }()
    
}
