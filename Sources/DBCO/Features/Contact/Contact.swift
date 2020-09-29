/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts

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
    
    var isValid: Bool {
        type.requiredFields.allSatisfy { field in
            values.contains {
                $0.field == field && $0.value?.isValid(for: field.fieldType) == true
            }
        }
    }
    
    mutating func setValue(_ value: String?, forFieldWithIdentifier identifier: UUID) {
        guard let index = values.firstIndex(where: { $0.identifier == identifier }) else {
            return
        }
        
        values[index].value = value
    }
}

enum Validation {
    case name
    case email
    case phoneNumber
    case number
    case general
}

enum FieldType {
    case text(Validation)
    case multilineText(Validation)
    case date
    case dropdown([String])
}

extension String {
    func isValid(for fieldType: FieldType) -> Bool {
        return !isEmpty
    }
}

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
    
    var fieldType: FieldType {
        switch self {
        case .firstName, .lastName, .companyName:
            return .text(.name)
        case .phoneNumber:
            return .text(.phoneNumber)
        case .email:
            return .text(.email)
        case .relation:
            return .dropdown(["Vriend of kennis", "Partner"])
        case .bsn:
            return .text(.number)
        case .profession:
            return .text(.general)
        case .notes:
            return .multilineText(.general)
        case .birthDate:
            return .date
        }
    }
    
    var allowsMultiple: Bool {
        switch self {
        case .phoneNumber, .email:
            return true
        default:
            return false
        }
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
