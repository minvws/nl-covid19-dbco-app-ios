/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts



class OldContact {
    let category: Task.Contact.Category
    
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
    
    init(category: Task.Contact.Category) {
        self.category = category
        setDefaults()
    }
    
    init(category: Task.Contact.Category, cnContact: CNContact) {
        self.category = category
        
        firstName = cnContact.contactFirstName
        lastName = cnContact.contactLastName
        phoneNumbers = cnContact.contactPhoneNumbers
        emailAddresses = cnContact.contactEmailAddresses
        birthDate = cnContact.contactBirthDay
        
        setDefaults()
    }
    
    init(category: Task.Contact.Category, name: String) {
        self.category = category
        
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

extension OldContact: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        let contact = OldContact(category: category)
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

struct GeneralDate: ContactValue {
    var value: String?
    var label: String?
    
    init(label: String?, value: String? = nil) {
        self.value = value
        self.label = label
    }
    
    init(label: String?, date: Date?) {
        if let date = date {
            self.value = GeneralDate.dateFormatter.string(from: date)
        }
        
        self.label = label
    }
    
    var dateValue: Date? {
        guard let value = value else {
            return nil
        }
        
        return GeneralDate.dateFormatter.date(from: value)
    }
        
    static let dateFormatter: DateFormatter = {
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

struct Text: ContactValue {
    var label: String?
    var value: String?
}

struct Options: ContactValue {
    var label: String?
    var value: String?
    let inputType: InputType
    
    init(label: String?, value: String?, options: [InputType.PickerOption]) {
        self.label = label
        self.value = value
        self.inputType = .picker(options: options)
    }
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
