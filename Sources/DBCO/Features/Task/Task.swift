/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum Task {
    case enterContactDetails(name: String, completed: Bool)
    
    var completed: Bool {
        switch self {
        case .enterContactDetails(_, let completed):
            return completed
        }
    }
}

final class TaskManager {
    
    private(set) var tasks: [Task] = [
        .enterContactDetails(name: "Aziz F", completed: false),
        .enterContactDetails(name: "Job J", completed: false),
        .enterContactDetails(name: "Lia B", completed: false),
        .enterContactDetails(name: "Thom Hoekstra", completed: true)
    ]
    
}
