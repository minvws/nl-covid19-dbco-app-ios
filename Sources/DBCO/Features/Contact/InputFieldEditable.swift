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
    case phoneNumber
    case picker(options: [PickerOption])
    case date(formatter: DateFormatter)
}

/// - Tag: Editable
protocol Editable {
    var value: String? { get set }
    
    var label: String? { get }
    var placeholder: String? { get }
}

extension Editable {
    var placeholder: String? { return nil }
}

/// - Tag: InputFieldEditable
protocol InputFieldEditable: Editable {
    var validator: Validator.Type? { get }
    var inputType: InputType { get }
    var keyboardType: UIKeyboardType { get }
    var autocapitalizationType: UITextAutocapitalizationType { get }
    var textContentType: UITextContentType? { get }
    var valueOptions: [String]? { get }
}

extension InputFieldEditable {
    var validator: Validator.Type? { return nil }
    var inputType: InputType { return .text }
    var keyboardType: UIKeyboardType { return .default }
    var autocapitalizationType: UITextAutocapitalizationType { return .sentences }
    var textContentType: UITextContentType? { return nil }
    var valueOptions: [String]? { return nil }
}

// MARK: - ContactValue Extensions
extension FirstName: InputFieldEditable {
    var label: String? { .contactInformationFirstName }
    var validator: Validator.Type? { NameValidator.self }
    var autocapitalizationType: UITextAutocapitalizationType { .words }
    var textContentType: UITextContentType? { .givenName }
}

extension LastName: InputFieldEditable {
    var label: String? { .contactInformationLastName }
    var validator: Validator.Type? { NameValidator.self }
    var autocapitalizationType: UITextAutocapitalizationType { .words }
    var textContentType: UITextContentType? { .familyName }
}

extension PhoneNumber: InputFieldEditable {
    var label: String? { .contactInformationPhoneNumber }
    var validator: Validator.Type? { PhoneNumberValidator.self }
    var inputType: InputType { .phoneNumber }
}

extension EmailAddress: InputFieldEditable {
    var label: String? { .contactInformationEmailAddress }
    var validator: Validator.Type? { EmailAddressValidator.self }
    var keyboardType: UIKeyboardType { .emailAddress }
    var autocapitalizationType: UITextAutocapitalizationType { .none }
    var textContentType: UITextContentType? { .emailAddress }
}

extension BirthDate: InputFieldEditable {
    var label: String? { .contactInformationBirthDate }
    var inputType: InputType { .date(formatter: BirthDate.birthDateFormatter) }
}

extension GeneralDate: InputFieldEditable {
    var placeholder: String? { .selectDate }
    var inputType: InputType { .date(formatter: GeneralDate.displayDateFormatter) }
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
