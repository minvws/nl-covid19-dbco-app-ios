/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct AppData: Codable {
    struct Constants {
        static let currentVersion = "1.0.0"
    }
    
    let version: String
    
    var dateOfSymptomOnset: Date
    var windowExpiresAt: Date
    var tasks: [Task]
    var questionnaires: [Questionnaire]
}

extension AppData {
    static var empty: AppData {
        AppData(version: Constants.currentVersion,
                dateOfSymptomOnset: .distantPast,
                windowExpiresAt: .distantFuture,
                tasks: [],
                questionnaires: [])
    }
}
