/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// The data stored by [CaseManager](x-source-tag://CaseManager).
/// Similar to [Case](x-source-tag://Case) but stores additional data like the questionnaires and a version string to allow for migrations.
///
/// # See also:
/// [Case](x-source-tag://Case),
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: AppData
struct AppData {
    struct Constants {
        static let currentVersion = "1.0.0"
    }
    
    let version: String
    
    var reference: String?
    var dateOfSymptomOnset: Date?
    var dateOfTest: Date?
    var symptomsKnown: Bool
    var windowExpiresAt: Date
    var tasks: [Task]
    var questionnaires: [Questionnaire]
    var symptoms: [String]
}

extension AppData {
    var asCase: Case {
        return Case(dateOfTest: dateOfTest,
                    dateOfSymptomOnset: dateOfSymptomOnset,
                    symptomsKnown: symptomsKnown,
                    windowExpiresAt: windowExpiresAt,
                    tasks: tasks,
                    symptoms: symptoms)
    }
    
    mutating func update(with caseResult: Case) {
        if dateOfSymptomOnset == nil {
            dateOfSymptomOnset = caseResult.dateOfSymptomOnset
        }

        if dateOfTest == nil {
            dateOfTest = caseResult.dateOfTest
        }

        if symptoms.isEmpty {
            symptoms = caseResult.symptoms
        }

        windowExpiresAt = caseResult.windowExpiresAt
        reference = caseResult.reference
        symptomsKnown = caseResult.symptomsKnown
    }
}

extension AppData {
    static var empty: AppData {
        AppData(version: Constants.currentVersion,
                reference: nil,
                dateOfSymptomOnset: nil,
                dateOfTest: nil,
                symptomsKnown: false,
                windowExpiresAt: .distantFuture,
                tasks: [],
                questionnaires: [],
                symptoms: [])
    }
}

extension AppData: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decode(String.self, forKey: .version)
        
        reference = try container.decodeIfPresent(String.self, forKey: .reference)
        dateOfSymptomOnset = try container.decodeIfPresent(Date.self, forKey: .dateOfSymptomOnset)
        dateOfTest = try container.decodeIfPresent(Date.self, forKey: .dateOfTest)
        symptomsKnown = try container.decode(Bool.self, forKey: .symptomsKnown)
        windowExpiresAt = try container.decode(Date.self, forKey: .windowExpiresAt)
        tasks = try container.decode([Task].self, forKey: .tasks)
        questionnaires = try container.decode([Questionnaire].self, forKey: .questionnaires)
        symptoms = (try container.decodeIfPresent([String].self, forKey: .symptoms)) ?? []
    }
}
