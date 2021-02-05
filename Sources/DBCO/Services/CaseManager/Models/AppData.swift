/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct AppData {
    struct Constants {
        static let currentVersion = "1.0.0"
    }
    
    let version: String
    
    var dateOfSymptomOnset: Date
    var windowExpiresAt: Date
    var tasks: [Task]
    var portalTasks: [Task]
    var questionnaires: [Questionnaire]
}

extension AppData {
    static var empty: AppData {
        AppData(version: Constants.currentVersion,
                dateOfSymptomOnset: .distantPast,
                windowExpiresAt: .distantFuture,
                tasks: [],
                portalTasks: [],
                questionnaires: [])
    }
}

extension AppData: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decode(String.self, forKey: .version)
        
        dateOfSymptomOnset = try container.decode(Date.self, forKey: .dateOfSymptomOnset)
        windowExpiresAt = try container.decode(Date.self, forKey: .windowExpiresAt)
        tasks = try container.decode([Task].self, forKey: .tasks)
        portalTasks = (try? container.decode([Task].self, forKey: .portalTasks)) ?? []
        questionnaires = try container.decode([Questionnaire].self, forKey: .questionnaires)
    }
}
