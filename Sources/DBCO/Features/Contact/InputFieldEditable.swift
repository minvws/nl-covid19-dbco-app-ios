/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

enum InputType {
    typealias PickerOption = (identifier: String, value: String)
    
    case text
    case number
    case picker(options: [PickerOption])
    case date(formatter: DateFormatter)
}

protocol Editable {
    var value: String? { get set }
    
    var label: String? { get }
    var placeholder: String? { get }
}

extension Editable {
    var placeholder: String? { return nil }
}

protocol InputFieldEditable: Editable {
    var showValidationState: Bool { get }
    var inputType: InputType { get }
    var keyboardType: UIKeyboardType { get }
    var autocapitalizationType: UITextAutocapitalizationType { get }
    var textContentType: UITextContentType? { get }
}

extension InputFieldEditable {
    var showValidationState: Bool { return false }
    var inputType: InputType { return .text }
    var keyboardType: UIKeyboardType { return .default }
    var autocapitalizationType: UITextAutocapitalizationType { return .sentences }
    var textContentType: UITextContentType? { return nil }
}

// MARK: - ContactValue Extensions
extension FirstName: InputFieldEditable {
    var label: String? { .contactInformationFirstName }
    var autocapitalizationType: UITextAutocapitalizationType { .words }
    var textContentType: UITextContentType? { .givenName }
}

extension LastName: InputFieldEditable {
    var label: String? { .contactInformationLastName }
    var autocapitalizationType: UITextAutocapitalizationType { .words }
    var textContentType: UITextContentType? { .familyName }
}

extension PhoneNumber: InputFieldEditable {
    var label: String? { .contactInformationPhoneNumber }
    var showValidationState: Bool { true }
    var inputType: InputType { .number }
}

extension EmailAddress: InputFieldEditable {
    var label: String? { .contactInformationEmailAddress }
    var showValidationState: Bool { true }
    var keyboardType: UIKeyboardType { .emailAddress }
    var autocapitalizationType: UITextAutocapitalizationType { .none }
    var textContentType: UITextContentType? { .emailAddress }
}

extension BirthDate: InputFieldEditable {
    var label: String? { .contactInformationBirthDate }
    var inputType: InputType { .date(formatter: BirthDate.birthDateFormatter) }
}

extension GeneralDate: InputFieldEditable {
    var inputType: InputType { .date(formatter: GeneralDate.dateFormatter) }
}

extension BSN: InputFieldEditable {
    var label: String? { .contactInformationBSN }
    var showValidationState: Bool { true }
    var inputType: InputType { .number }
}

extension Text: InputFieldEditable {
    var textContentType: UITextContentType? { .none }
}

extension Options: InputFieldEditable {}

