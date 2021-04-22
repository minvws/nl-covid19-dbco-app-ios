/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Task {
    
    /// Used for calculating the [task's status](x-source-tag://Task.status) and the state of the Inform section in [ContactQuestionnaireViewModel](x-source-tag://ContactQuestionnaireViewModel)
    /// When the GGD will inform the contact, a valid email or phonenumber is required,
    /// in any other case the app just needs to know if the user has informed the contact
    var isOrCanBeInformed: Bool {
        guard taskType == .contact else { return false }
        
        switch contact.communication {
        case .index, .unknown:
            return contact.informedByIndexAt != nil
        case .staff:
            // The GGD can only contact when there's a email or phoneNumber filled in
            return contactEmail != nil || contactPhoneNumber != nil
        }
    }
    
}
