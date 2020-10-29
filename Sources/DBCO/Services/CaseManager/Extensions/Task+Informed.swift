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
            return contact.didInform
        case .staff:
            // The GGD can only contact when there's a email or phoneNumber filled in
            return contactEmail?.nilIfEmpty != nil || contactPhoneNumber?.nilIfEmpty != nil
        case .none:
            return false
        }
    }
    
}
