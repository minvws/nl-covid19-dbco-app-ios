/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol Task {
    var identifier: String { get }
    var completed: Bool { get }
    var isSynced: Bool { get }
}

struct ContactDetailsTask: Task {
    let name: String
    
    let identifier: String
    let completed: Bool
    let isSynced: Bool
}

final class TaskManager {
    
    private(set) var tasks: [Task] = [
        ContactDetailsTask(name: "Aziz F", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "Job J", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "J Attema", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "Thom H", identifier: UUID().uuidString, completed: false, isSynced: false)
    ]
    
}
