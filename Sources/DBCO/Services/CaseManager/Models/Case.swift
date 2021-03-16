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
    let reference: String?
    let dateOfSymptomOnset: Date?
    let dateOfTest: Date?
    @ISO8601DateFormat var windowExpiresAt: Date
    let tasks: [Task]
    let symptoms: [String]
    
    init(dateOfTest: Date?, dateOfSymptomOnset: Date?, windowExpiresAt: Date, tasks: [Task], symptoms: [String]) {
        self.dateOfTest = dateOfTest
        self.dateOfSymptomOnset = dateOfSymptomOnset
        self.windowExpiresAt = windowExpiresAt
        self.tasks = tasks
        self.symptoms = symptoms
        self.reference = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        reference = try container.decodeIfPresent(String.self, forKey: .reference)
        
        dateOfSymptomOnset = try container.decodeIfPresent(Date.self, forKey: .dateOfSymptomOnset)
        dateOfTest = try container.decode(Date.self, forKey: .dateOfTest) // Should always exist
        
        _windowExpiresAt = try container.decode(ISO8601DateFormat.self, forKey: .windowExpiresAt)
        tasks = try container.decode([Task].self, forKey: .tasks)
        symptoms = (try container.decodeIfPresent([String].self, forKey: .symptoms)) ?? []
    }
}
