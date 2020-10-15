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

struct Answer {
    let uuid: UUID
    let questionUuid: UUID
    let lastModified: Date
    
    enum Value: CustomStringConvertible, Equatable {
        case classificationDetails(livedTogetherRisk: Bool?,
                                   durationRisk: Bool?,
                                   distanceRisk: Bool?,
                                   otherRisk: Bool?)
        case contactDetails(firstName: String?,
                            lastName: String?,
                            email: String?,
                            phoneNumber: String?)
        case date(Date?)
        case open(String?)
        case multipleChoice(AnswerOption?)
        
        var description: String {
            switch self {
            case .classificationDetails(let livedTogetherRisk, let durationRisk, let distanceRisk, let otherRisk):
                return "classificationDetails(\(String(describing: livedTogetherRisk)), \(String(describing: durationRisk)), \(String(describing: distanceRisk)), \(String(describing: otherRisk)))"
            case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
                return "contactDetails(\(String(describing: firstName)), \(String(describing: lastName)), \(String(describing: email)), \(String(describing: phoneNumber)))"
            case .date(let date):
                return "date(\(String(describing: date)))"
            case .open(let value):
                return "open(\(String(describing: value)))"
            case .multipleChoice(let option):
                return "multipleChoice(\(String(describing: option)))"
            }
        }
        
        static func == (lhs: Answer.Value, rhs: Answer.Value) -> Bool {
            return lhs.description == rhs.description
        }
    }
    
    let value: Value
    
    var progress: Double {
        switch value {
        case .classificationDetails(let livedTogetherRisk, let durationRisk, let distanceRisk, let otherRisk):
            let valueCount = [livedTogetherRisk, durationRisk, distanceRisk, otherRisk]
                .compactMap { $0 }
                .count
            
            return Double(valueCount) / 4
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            let valueCount = [firstName, lastName, email, phoneNumber]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .count
            
            return Double(valueCount) / 4
        case .date(let value):
            return value != nil ? 1 : 0
        case .open(let value):
            return value?.isEmpty == false ? 1 : 0
        case .multipleChoice(let value):
            return value != nil ? 1 : 0
        }
    }
}

// For Prefilling
extension Answer.Value {
    static func contactDetails(contact: OldContact) -> Self {
        return .contactDetails(firstName: contact.firstName.value,
                               lastName: contact.lastName.value,
                               email: contact.emailAddresses.first?.value,
                               phoneNumber: contact.phoneNumbers.first?.value)
    }
}

struct QuestionnaireResult {
    let questionnaireUuid: UUID
    let answers: [Answer]
    
    var progress: Double {
        answers.reduce(0) { $0 + ($1.progress / Double(answers.count)) }
    }
}
