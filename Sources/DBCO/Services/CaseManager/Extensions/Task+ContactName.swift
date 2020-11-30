/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Task {
    /// Searches for a .contactDetails answer in the results and returns the firstName and lastName combined.
    /// Falls back to the value of `label` if no answer could be found
    var contactName: String? {
        questionnaireResult?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(let firstName, let lastName, _, _):
                    let fullName = [firstName, lastName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    
                    return fullName.isEmpty ? nil : fullName
                default:
                    return nil
                }
            }
            .first ?? label
    }
    
    /// Searches for a .contactDetails answer in the results and returns the firstName.
    /// Falls back to the value of `label` if answer could be found
    var contactFirstName: String? {
        questionnaireResult?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(let firstName, _, _, _):
                    return firstName
                default:
                    return nil
                }
            }
            .first ?? label
    }
    
    /// Searches for a .contactDetails answer in the results and returns the phoneNumber.
    var contactPhoneNumber: String? {
        questionnaireResult?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(_, _, _, let phoneNumber):
                    return phoneNumber
                default:
                    return nil
                }
            }
            .first
    }
    
    /// Searches for a .contactDetails answer in the results and returns the email.
    var contactEmail: String? {
        questionnaireResult?.answers
            .compactMap {
                switch $0.value {
                case .contactDetails(_, _, let email, _):
                    return email
                default:
                    return nil
                }
            }
            .first
    }
}
