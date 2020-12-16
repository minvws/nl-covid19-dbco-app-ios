/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Task {
    
    var isUnfinished: Bool {
        guard !deletedByIndex else { return false }
        guard let result = questionnaireResult else {
            return true
        }
        
        return !result.hasAllEssentialAnswers
    }
    
}
