/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

enum InputType {
    case text
    case number
    case picker(options: [String])
    case date(formatter: DateFormatter)
}

protocol InputFieldEditable {
    var value: String? { get set }
    
    static var label: String { get }
    static var placeholder: String? { get }
    static var inputType: InputType { get }
    static var keyboardType: UIKeyboardType { get }
    static var autocapitalizationType: UITextAutocapitalizationType { get }
    static var textContentType: UITextContentType? { get }
}

extension InputFieldEditable {
    static var placeholder: String? { return nil }
    static var inputType: InputType { return .text }
    static var keyboardType: UIKeyboardType { return .default }
    static var autocapitalizationType: UITextAutocapitalizationType { return .sentences }
    static var textContentType: UITextContentType? { return nil }
}

// MARK: - ContactValue Extensions
extension FirstName: InputFieldEditable {
    static let label: String = .contactInformationFirstName
    static let autocapitalizationType: UITextAutocapitalizationType = .words
    static let textContentType: UITextContentType? = .givenName
}

extension LastName: InputFieldEditable {
    static let label: String = .contactInformationLastName
    static let autocapitalizationType: UITextAutocapitalizationType = .words
    static let textContentType: UITextContentType? = .familyName
}

extension PhoneNumber: InputFieldEditable {
    static let label: String = .contactInformationPhoneNumber
    static let inputType: InputType = .number
}

extension EmailAddress: InputFieldEditable {
    static let label: String = .contactInformationEmailAddress
    static let keyboardType: UIKeyboardType = .emailAddress
    static let autocapitalizationType: UITextAutocapitalizationType = .none
    static let textContentType: UITextContentType? = .emailAddress
}

extension BirthDate: InputFieldEditable {
    static let label: String = .contactInformationBirthDate
    static let inputType: InputType = .date(formatter: birthDateFormatter)
}

extension CompanyName: InputFieldEditable {
    static let label: String = .contactInformationCompanyName
    static let autocapitalizationType: UITextAutocapitalizationType = .words
    static let textContentType: UITextContentType? = .organizationName
}

extension BSN: InputFieldEditable {
    static let label: String = .contactInformationBSN
    static let placeholder: String? = "9-cijferig nummer"
    static let inputType: InputType = .number
}

extension RelationType: InputFieldEditable {
    static let label: String = .contactInformationRelationType
    static let inputType: InputType = .picker(options: ["Familie", "Vriend of kennis"])
}

extension Profession: InputFieldEditable {
    static let label: String = .contactInformationProfession
    static let textContentType: UITextContentType? = .jobTitle
}

extension Notes: InputFieldEditable {
    static let label: String = .contactInformationNotes
    static let textContentType: UITextContentType? = .none
}

