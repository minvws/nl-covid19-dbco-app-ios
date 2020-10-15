/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol OldTask {
    var identifier: String { get }
    var status: Task.Status { get }
    var isSynced: Bool { get }
}

struct ContactDetailsTask: OldTask {
    let name: String
    var contact: OldContact?
    var preferredStaffContact: Bool
    
    let identifier: String
    var status: Task.Status
    var isSynced: Bool
}
