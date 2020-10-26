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
    enum CaseError: Error {
        case dateDecodingError
        case tasksDecodingError
    }
    
    let dateOfSymptomOnset: Date
    let tasks: [Task]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tasks = try container.decode([Task].self, forKey: .tasks)
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = try container.decode(String.self, forKey: .dateOfSymptomOnset)
        guard let date = dateFormatter.date(from: dateString) else {
            throw CaseError.dateDecodingError
        }
        
        dateOfSymptomOnset = date
    }
}
