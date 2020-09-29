/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

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

extension ContactField {
    
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
    
}

extension Contact {
    
    var isValid: Bool {
        type.requiredFields.allSatisfy { field in
            values.contains {
                $0.field == field && $0.value?.isValid(for: field.fieldType) == true
            }
        }
    }
    
}
