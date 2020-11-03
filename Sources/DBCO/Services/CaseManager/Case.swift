/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// The case associated with the pairing code. Wrapper for the tasks and the date the symptoms started.
///
/// # See also:
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: Case
struct Case: Codable {
    let dateOfSymptomOnset: Date
    let tasks: [Task]
}
