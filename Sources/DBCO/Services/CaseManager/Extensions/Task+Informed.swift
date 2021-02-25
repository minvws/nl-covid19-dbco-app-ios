/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Task {
    
    var isOrCanBeInformed: Bool {
        guard taskType == .contact else { return false }
        
        switch contact.communication {
        case .index:
            return contact.informedByIndexAt != nil
        case .staff:
            // The GGD can only contact when there's a email or phoneNumber filled in
            return contactEmail != nil || contactPhoneNumber != nil
        case .unknown:
            return false
        }
    }
    
}
