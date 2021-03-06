/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

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
    var valueOptions: [String]?
    var placeholder: String?
}

struct EmailAddress: ContactValue {
    var value: String?
    var valueOptions: [String]?
    var placeholder: String? 
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
        formatter.locale = .display
        
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
            self.value = GeneralDate.displayDateFormatter.string(from: date)
        }
        
        self.label = label
    }
    
    var dateValue: Date? {
        get {
            guard let value = value else {
                return nil
            }
            
            return GeneralDate.valueDateFormatter.date(from: value)
        }
        
        set {
            guard let date = newValue else {
                self.value = nil
                return
            }
            
            self.value = GeneralDate.valueDateFormatter.string(from: date)
        }
    }
        
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = .display
        formatter.timeZone = TimeZone.current
        
        return formatter
    }()
    
    static let valueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = .display
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter
    }()
}

struct BSN: ContactValue {
    var value: String?
}

struct Text: ContactValue {
    var label: String?
    var value: String?
    var labelFont: UIFont? = Theme.fonts.subhead
}

struct Options: ContactValue {
    var label: String?
    var value: String?
    var labelFont: UIFont? = Theme.fonts.subhead
    let inputType: InputType
    
    init(label: String?, value: String?, options: [InputType.PickerOption]) {
        self.label = label
        self.value = value
        self.inputType = .picker(options: options)
    }
}

extension CNContact {
    
    private func setToNilIfEmpty(_ value: String) -> String? {
        return value.isEmpty ? nil : value
    }
    
    var contactFirstName: FirstName {
        FirstName(value: isKeyAvailable(CNContactGivenNameKey) ? setToNilIfEmpty(givenName) : nil)
    }
    
    var contactLastName: LastName {
        LastName(value: isKeyAvailable(CNContactFamilyNameKey) ? setToNilIfEmpty(familyName) : nil)
    }
    
    var contactPhoneNumbers: [PhoneNumber] {
        if isKeyAvailable(CNContactPhoneNumbersKey) {
            let invalidCharacters = PhoneNumberValidator.validCharacters.inverted
            return phoneNumbers.map { PhoneNumber(value:
                                                    setToNilIfEmpty($0.value.stringValue)?
                                                    .components(separatedBy: invalidCharacters)
                                                    .joined()) }
        }
        
        return []
    }
    
    var contactEmailAddresses: [EmailAddress] {
        if isKeyAvailable(CNContactEmailAddressesKey) {
            return emailAddresses.map { EmailAddress(value: setToNilIfEmpty($0.value as String)) }
        }
        
        return []
    }
    
    var contactBirthDay: BirthDate {
        BirthDate(date: isKeyAvailable(CNContactBirthdayKey) ? birthday?.date : nil)
    }
}
