/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct AppData: Codable {
    let dateOfSymptomOnset: Date
    let pairing: Pairing
}

extension AppData {
    static var empty: AppData {
        AppData(dateOfSymptomOnset: Date(timeIntervalSinceReferenceDate: 0), pairing: .empty)
    }
}
