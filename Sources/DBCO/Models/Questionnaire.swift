/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum AnswerTrigger: String, Codable {
    case setCommunicationToIndex = "communication_index"
    case setCommunicationToStaff = "communication_staff"
}

struct AnswerOption: Codable {
    let label: String
    let value: String
    let trigger: AnswerTrigger?
}

struct Question: Codable {
    enum Group: String, Codable {
        case classification
        case contactDetails = "contactdetails"
    }
    
    enum QuestionType: String, Codable {
        case classificationDetails = "classificationdetails"
        case date
        case contactDetails = "contactdetails"
        case open
        case multipleChoice = "multiplechoice"
    }

    let uuid: UUID
    let group: Group
    let questionType: QuestionType
    let label: String?
    let description: String?
    let relevantForCategories: [Task.Contact.Category]
    let answerOptions: [AnswerOption]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        group = try container.decode(Group.self, forKey: .group)
        questionType = try container.decode(QuestionType.self, forKey: .questionType)
        label = try container.decode(String?.self, forKey: .label)
        description = try container.decode(String?.self, forKey: .description)
        
        struct CategoryWrapper: Codable {
            let category: Task.Contact.Category
        }
        
        let categories = try container.decode([CategoryWrapper].self, forKey: .relevantForCategories)
        relevantForCategories = categories.map { $0.category }
        
        answerOptions = try? container.decode([AnswerOption]?.self, forKey: .answerOptions)
    }
}

struct Questionnaire: Codable {
    let uuid: UUID
    let taskType: Task.TaskType
    let questions: [Question]
}
