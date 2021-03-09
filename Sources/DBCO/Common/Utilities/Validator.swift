/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum ValidationResult {
    case valid
    case invalid
    case unknown
}

protocol ValidationTask {
    func cancel()
}

protocol Validator {
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask
}

private struct InlineTask: ValidationTask {
    let completionHandler: (ValidationResult) -> Void
    
    init(_ completionHandler: @escaping (ValidationResult) -> Void) {
        self.completionHandler = completionHandler
    }
    
    func applying(_ result: ValidationResult) -> Self {
        completionHandler(result)
        return self
    }
    
    func cancel() {}
}

struct PhoneNumberValidator: Validator {
    static let validCharacters: CharacterSet = {
        var validCharacters = CharacterSet.decimalDigits
        validCharacters.insert(charactersIn: "+- ")
        return validCharacters
    }()
    
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask {
        let task = InlineTask(completionHandler)
        
        guard let value = value else { return task.applying(.unknown) }
    
        let strippedValue = value.components(separatedBy: validCharacters.inverted).joined()
        
        guard strippedValue == value else { return task.applying(.invalid) }
        guard strippedValue.count >= 6 else { return task.applying(.invalid) }
        
        return task.applying(.valid)
    }
}

struct EmailAddressValidator: Validator {
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask {
        let task = InlineTask(completionHandler)
        
        guard let value = value else { return task.applying(.unknown) }
        
        let emailFormat = "[A-Z0-9a-z.!#$%&'*+-/=?^_`{|}~]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)

        if emailPredicate.evaluate(with: value) {
            return task.applying(.valid)
        } else {
            return task.applying(.invalid)
        }
    }
}
