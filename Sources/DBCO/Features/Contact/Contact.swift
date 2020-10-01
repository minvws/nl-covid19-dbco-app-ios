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

class Contact {
    let type: ContactType
    
    var firstName = FirstName()
    var lastName = LastName()
    var phoneNumbers = [PhoneNumber]()
    var emailAddresses = [EmailAddress]()
    var birthDate = BirthDate()
    var bsn = BSN()
    var companyName = CompanyName()
    var relationType = RelationType()
    var profession = Profession()
    var notes = Notes()
    
    var fullName: String {
        [firstName.value, lastName.value].compactMap { $0 }.joined(separator: " ")
    }
    
    init(type: ContactType) {
        self.type = type
        setDefaults()
    }
    
    init(type: ContactType, cnContact: CNContact) {
        self.type = type
        
        firstName = cnContact.contactFirstName
        lastName = cnContact.contactLastName
        phoneNumbers = cnContact.contactPhoneNumbers
        emailAddresses = cnContact.contactEmailAddresses
        birthDate = cnContact.contactBirthDay
        
        setDefaults()
    }
    
    init(type: ContactType, name: String) {
        self.type = type
        
        let nameParts = name.split(separator: " ")
        switch nameParts.count {
        case 2...:
            firstName.value = String(nameParts.first!)
            lastName.value = String(nameParts.last!)
        case 1:
            firstName.value = String(nameParts.first!)
        default:
            break
        }
        
        setDefaults()
    }
    
    private func setDefaults() {
        if phoneNumbers.isEmpty {
            phoneNumbers.append(PhoneNumber())
        }
        
        if emailAddresses.isEmpty {
            emailAddresses.append(EmailAddress())
        }
    }
    
    var isValid: Bool {
        return false
    }
}

extension Contact: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        let contact = Contact(type: type)
        contact.firstName = firstName
        contact.lastName = lastName
        contact.phoneNumbers = phoneNumbers
        contact.emailAddresses = emailAddresses
        contact.birthDate = birthDate
        contact.bsn = bsn
        contact.companyName = companyName
        contact.relationType = relationType
        contact.profession = profession
        contact.notes = notes
        
        return contact
    }

}

protocol ContactValue {
    var value: String? { get set }
}

struct FirstName: ContactValue {
    var value: String?
}

struct LastName: ContactValue {
    var value: String?
}

struct PhoneNumber: ContactValue {
    var value: String?
}

struct EmailAddress: ContactValue {
    var value: String?
}

struct BirthDate: ContactValue {
    var value: String?
    
    init(value: String? = nil) {
        self.value = value
    }
    
    init(date: Date?) {
        if let date = date {
            self.value = BirthDate.birthDateFormatter.string(from: date)
        }
    }
        
    static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        
        return formatter
    }()
}

struct CompanyName: ContactValue {
    var value: String?
}

struct BSN: ContactValue {
    var value: String?
}

struct RelationType: ContactValue {
    var value: String?
}

struct Profession: ContactValue {
    var value: String?
}

struct Notes: ContactValue {
    var value: String?
}

extension CNContact {
    
    var contactFirstName: FirstName {
        FirstName(value: isKeyAvailable(CNContactGivenNameKey) ? givenName : nil)
    }
    
    var contactLastName: LastName {
        LastName(value: isKeyAvailable(CNContactFamilyNameKey) ? familyName : nil)
    }
    
    var contactPhoneNumbers: [PhoneNumber] {
        if isKeyAvailable(CNContactPhoneNumbersKey) {
            return phoneNumbers.map { PhoneNumber(value: $0.value.stringValue)  }
        }
        
        return []
    }
    
    var contactEmailAddresses: [EmailAddress] {
        if isKeyAvailable(CNContactEmailAddressesKey) {
            return emailAddresses.map { EmailAddress(value: $0.value as String)  }
        }
        
        return []
    }
    
    var contactBirthDay: BirthDate {
        BirthDate(date: isKeyAvailable(CNContactBirthdayKey) ? birthday?.date : nil)
    }
}
