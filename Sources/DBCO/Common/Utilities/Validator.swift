/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum ValidationResult {
    case valid
    case invalid(String?)
    case warning(String?)
    case unknown
}

protocol ValidationTask: class {
    func cancel()
}

protocol Validator {
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask
}

private class SimpleTask: ValidationTask {
    let completionHandler: (ValidationResult) -> Void
    private(set) var isCancelled: Bool = false
    
    init(_ completionHandler: @escaping (ValidationResult) -> Void) {
        self.completionHandler = completionHandler
    }
    
    func applying(_ result: ValidationResult) -> Self {
        DispatchQueue.main.async {
            guard !self.isCancelled else { return }
            self.completionHandler(result)
        }
        
        return self
    }
    
    func apply(_ result: ValidationResult) {
        DispatchQueue.main.async {
            guard !self.isCancelled else { return }
            self.completionHandler(result)
        }
    }
    
    func cancel() {
        isCancelled = true
    }
}

// MARK: - PhoneNumberValidator
struct PhoneNumberValidator: Validator {
    static let validCharacters: CharacterSet = {
        var validCharacters = CharacterSet.decimalDigits
        validCharacters.insert(charactersIn: "+- ")
        return validCharacters
    }()
    
    static let digitCharacters: CharacterSet = {
        var digitCharacters = CharacterSet.decimalDigits
        digitCharacters.insert(charactersIn: "+")
        return digitCharacters
    }()
    
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask {
        let task = SimpleTask(completionHandler)
        
        guard let value = value else { return task.applying(.unknown) }
    
        let strippedValue = value.components(separatedBy: validCharacters.inverted).joined()
        
        guard strippedValue == value else { return task.applying(.invalid(.contactInformationPhoneNumberGeneralError)) }
        
        let digits = value
            .components(separatedBy: digitCharacters.inverted)
            .joined()
        
        switch digits.count {
        case ...9:
            return task.applying(.invalid(.contactInformationPhoneNumberTooShortError))
        case 10:
            return task.applying(.valid)
        case 11...13:
            let countryCodes = ["+31", "031", "0031",  // Netherlands country code
                                "+32", "032", "0032",  // Belgium country code
                                "+49", "049", "0049"] // Germany country code
            
            if countryCodes.contains(where: digits.starts) {
                return task.applying(.valid)
            } else {
                return task.applying(.invalid(.contactInformationPhoneNumberGeneralError))
            }
        default:
            return task.applying(.invalid(.contactInformationPhoneNumberTooLongError))
        }
    }
}

// MARK: - EmailAddressValidator
struct EmailAddressValidator: Validator {
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask {
        let task = SimpleTask(completionHandler)
        
        guard let value = value else { return task.applying(.unknown) }
        
        let emailFormat = "[A-Z0-9a-z.!#$%&'*+-/=?^_`{|}~]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)

        if emailPredicate.evaluate(with: value) {
            return task.applying(.valid)
        } else {
            return task.applying(.invalid(.contactInformationEmailAddressGeneralError))
        }
    }
}

// MARK: - NameValidator
struct NameValidator: Validator {
    
    static func validate(_ value: String?, completionHandler: @escaping (ValidationResult) -> Void) -> ValidationTask {
        let task = SimpleTask(completionHandler)
        
        guard let value = value else { return task.applying(.unknown) }
        guard !value.isEmpty else { return task.applying(.unknown) }
        
        DispatchQueue.global(qos: .utility).async {
            let failingConditions = [
                containsOnlyConsonants,
                containsOnlyVowels,
                containsUppercasedCharacterAfterFirst,
                containsInvalidCharacters,
                endsWithInvalidSuffix,
                containsInvalidName
            ]
            
            let hasFailingCondition = failingConditions.contains { $0(value) }
            
            if hasFailingCondition {
                task.apply(.warning(.contactInformationNameWarning))
            } else {
                task.apply(.unknown)
            }
        }
        
        return task
    }
    
    static let vowels = CharacterSet(charactersIn: "aeiouyAEIOUY")
    static let consonants = CharacterSet.letters.subtracting(vowels)
    static let validCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: " -'’"))
    static let invalidCharacters = validCharacters.inverted
    
    static let invalidNames: [String] = {
        guard let path = Bundle.main.path(forResource: "Invalid names", ofType: "txt", inDirectory: "Validation") else { return [] }
        
        do {
            return try String(contentsOfFile: path)
                .lowercased()
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }
        } catch {
            return []
        }
    }()
    
    static let invalidSuffixes: [String] = {
        guard let path = Bundle.main.path(forResource: "Invalid suffixes", ofType: "txt", inDirectory: "Validation") else { return [] }
        
        do {
            return try String(contentsOfFile: path)
                .lowercased()
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }
        } catch {
            return []
        }
    }()
    
    // MARK: - Failing conditions
    static func containsOnlyConsonants(_ value: String) -> Bool {
        let strippedValue = value.lowercased().components(separatedBy: consonants).joined()
        
        return strippedValue.isEmpty
    }
    
    static func containsOnlyVowels(_ value: String) -> Bool {
        let strippedValue = value.lowercased().components(separatedBy: vowels).joined()
        
        return strippedValue.isEmpty
    }
    
    static func containsUppercasedCharacterAfterFirst(_ value: String) -> Bool {
        return value.components(separatedBy: CharacterSet(charactersIn: " -")).contains { word in
            guard word.count > 1 else { return false }
            return word.suffix(word.count - 1).contains(where: \.isUppercase)
        }
    }
    
    static func containsInvalidCharacters(_ value: String) -> Bool {
        let containsInvalidCharacters = value.unicodeScalars.contains(where: invalidCharacters.contains)

        return containsInvalidCharacters
    }
    
    static func endsWithInvalidSuffix(_ value: String) -> Bool {
        return invalidSuffixes.contains(where: value.hasSuffix)
    }
    
    static func containsInvalidName(_ value: String) -> Bool {
        return invalidNames.contains(where: value.lowercased().contains)
    }
    
}
