/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// - Tag: AnswerTrigger
enum AnswerTrigger: String, Codable {
    case setCommunicationToIndex = "communication_index"
    case setCommunicationToStaff = "communication_staff"
}

struct AnswerOption: Codable {
    let label: String
    let value: String
    let trigger: AnswerTrigger?
}

/// - Tag: Question
struct Question {
    enum Group: String, Codable {
        case classification
        case contactDetails = "contactdetails"
        case other
    }
    
    enum QuestionType: String, Codable {
        case classificationDetails = "classificationdetails"
        case date
        case contactDetails = "contactdetails"
        case contactDetailsFull = "contactdetails_full"
        case open
        case multipleChoice = "multiplechoice"
        
        /// This case is not supported in the API.
        /// The app injects a question of this type in the contact [Questionnaire](x-source-tag://Questionnaire) to support the dateOfLastExposure property at the Task level.
        /// Answers to a question with this type should not be sent to the backend.
        ///
        /// # See also
        /// [setQuestionnaires(_ questionnaires: [Questionnaire])](x-source-tag://CaseManager.setQuestionnaires)
        ///
        /// - Tag: lastExposureDate
        case lastExposureDate
    }

    let uuid: UUID
    let group: Group
    let questionType: QuestionType
    let label: String?
    let description: String?
    let relevantForCategories: [Task.Contact.Category]
    let answerOptions: [AnswerOption]?
    
    init(uuid: UUID, group: Group, questionType: QuestionType, label: String?, description: String?, relevantForCategories: [Task.Contact.Category], answerOptions: [AnswerOption]?) {
        self.uuid = uuid
        self.group = group
        self.questionType = questionType
        self.label = label
        self.description = description
        self.relevantForCategories = relevantForCategories
        self.answerOptions = answerOptions
    }
}

extension Question: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case group
        case questionType
        case label
        case description
        case relevantForCategories
        case answerOptions
    }
    
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(group, forKey: .group)
        try container.encode(questionType, forKey: .questionType)
        try container.encode(label, forKey: .label)
        try container.encode(description, forKey: .description)
        
        struct CategoryWrapper: Codable {
            let category: Task.Contact.Category
        }
        
        let categories = relevantForCategories.map(CategoryWrapper.init)
        
        try container.encode(categories, forKey: .relevantForCategories)
        
        try container.encode(answerOptions, forKey: .answerOptions)
    }
    
}

/// Represents the questionnaires needed to complete tasks.
/// Questionnaires are linked to tasks via the taskType property.
/// Currently only the `contact` task is supported.
///
/// # See also:
/// [Task](x-source-tag://Task),
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: Questionnaire
struct Questionnaire: Codable {
    let uuid: UUID
    let taskType: Task.TaskType
    let questions: [Question]
}

/// - Tag: Answer
struct Answer: Codable, Equatable {
    let uuid: UUID
    let questionUuid: UUID
    @ISO8601DateFormat var lastModified: Date
    
    enum Value: CustomStringConvertible, Equatable {
        case classificationDetails(category1Risk: Bool?,
                                   category2aRisk: Bool?,
                                   category2bRisk: Bool?,
                                   category3Risk: Bool?)
        case contactDetails(firstName: String?,
                            lastName: String?,
                            email: String?,
                            phoneNumber: String?)
        case contactDetailsFull(firstName: String?,
                            lastName: String?,
                            email: String?,
                            phoneNumber: String?)
        case date(Date?)
        case open(String?)
        case multipleChoice(AnswerOption?)
        
        /// See [lastExposureDate](x-source-tag://lastExposureDate)
        case lastExposureDate(AnswerOption?)
        
        var description: String {
            switch self {
            case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
                return "classificationDetails(\(String(describing: category1Risk)), \(String(describing: category2aRisk)), \(String(describing: category2bRisk)), \(String(describing: category3Risk)))"
            case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
                return "contactDetails(\(String(describing: firstName)), \(String(describing: lastName)), \(String(describing: email)), \(String(describing: phoneNumber)))"
            case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
                return "contactDetailsFull(\(String(describing: firstName)), \(String(describing: lastName)), \(String(describing: email)), \(String(describing: phoneNumber)))"
            case .date(let date):
                return "date(\(String(describing: date)))"
            case .lastExposureDate(let option):
                return "lastExposureDate(\(String(describing: option)))"
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
    
    var value: Value
}

extension Answer.Value: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case firstName
        case lastName
        case email
        case phoneNumber
        case value
        case category1Risk
        case category2ARisk
        case category2BRisk
        case category3Risk
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Question.QuestionType.self, forKey: .type)
        
        switch type {
        case .classificationDetails:
            self = .classificationDetails(category1Risk: try container.decode(Bool?.self, forKey: .category1Risk),
                                          category2aRisk: try container.decode(Bool?.self, forKey: .category2ARisk),
                                          category2bRisk: try container.decode(Bool?.self, forKey: .category2BRisk),
                                          category3Risk: try container.decode(Bool?.self, forKey: .category3Risk))
        case .contactDetails:
            self = .contactDetails(firstName: try container.decode(String?.self, forKey: .firstName),
                                   lastName: try container.decode(String?.self, forKey: .lastName),
                                   email: try container.decode(String?.self, forKey: .email),
                                   phoneNumber: try container.decode(String?.self, forKey: .phoneNumber))
        case .contactDetailsFull:
            self = .contactDetailsFull(firstName: try container.decode(String?.self, forKey: .firstName),
                                       lastName: try container.decode(String?.self, forKey: .lastName),
                                       email: try container.decode(String?.self, forKey: .email),
                                       phoneNumber: try container.decode(String?.self, forKey: .phoneNumber))
        case .date:
            self = .date(try container.decode(Date?.self, forKey: .value))
        case .open:
            self = .open(try container.decode(String?.self, forKey: .value))
        case .multipleChoice:
            self = .multipleChoice(try container.decode(AnswerOption?.self, forKey: .value))
        case .lastExposureDate:
            self = .lastExposureDate(try container.decode(AnswerOption?.self, forKey: .value))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch encoder.target {
        case .internalStorage, .unknown:
            try encodeForLocalStorage(to: encoder)
        case .api:
            try encodeForAPI(to: encoder)
        }
    }
    
    private func encodeForLocalStorage(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
            try container.encode(Question.QuestionType.classificationDetails, forKey: .type)
            try container.encode(category1Risk, forKey: .category1Risk)
            try container.encode(category2aRisk, forKey: .category2ARisk)
            try container.encode(category2bRisk, forKey: .category2BRisk)
            try container.encode(category3Risk, forKey: .category3Risk)
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            try container.encode(Question.QuestionType.contactDetails, forKey: .type)
            try container.encode(firstName, forKey: .firstName)
            try container.encode(lastName, forKey: .lastName)
            try container.encode(email, forKey: .email)
            try container.encode(phoneNumber, forKey: .phoneNumber)
        case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
            try container.encode(Question.QuestionType.contactDetailsFull, forKey: .type)
            try container.encode(firstName, forKey: .firstName)
            try container.encode(lastName, forKey: .lastName)
            try container.encode(email, forKey: .email)
            try container.encode(phoneNumber, forKey: .phoneNumber)
        case .date(let date):
            try container.encode(Question.QuestionType.date, forKey: .type)
            try container.encode(date, forKey: .value)
        case .lastExposureDate(let date):
            try container.encode(Question.QuestionType.lastExposureDate, forKey: .type)
            try container.encode(date, forKey: .value)
        case .open(let value):
            try container.encode(Question.QuestionType.open, forKey: .type)
            try container.encode(value, forKey: .value)
        case .multipleChoice(let option):
            try container.encode(Question.QuestionType.multipleChoice, forKey: .type)
            try container.encode(option, forKey: .value)
        }
    }
    
    private func encodeForAPI(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk):
            try container.encode(category1Risk ?? false, forKey: .category1Risk)
            try container.encode(category2aRisk ?? false, forKey: .category2ARisk)
            try container.encode(category2bRisk ?? false, forKey: .category2BRisk)
            try container.encode(category3Risk ?? false, forKey: .category3Risk)
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber):
            try container.encode(firstName, forKey: .firstName)
            try container.encode(lastName, forKey: .lastName)
            try container.encode(email, forKey: .email)
            try container.encode(phoneNumber, forKey: .phoneNumber)
        case .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
            try container.encode(firstName, forKey: .firstName)
            try container.encode(lastName, forKey: .lastName)
            try container.encode(email, forKey: .email)
            try container.encode(phoneNumber, forKey: .phoneNumber)
        case .date(let date):
            try container.encode(date, forKey: .value)
        case .lastExposureDate(let date):
            try container.encode(date?.value, forKey: .value)
        case .open(let value):
            try container.encode(value, forKey: .value)
        case .multipleChoice(let option):
            try container.encode(option?.value, forKey: .value)
        }
    }
}

/// Represents a filled out questionnaire
///
/// # See also:
/// [Questionnaire](x-source-tag://Questionnaire),
/// [Task](x-source-tag://Task),
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: QuestionnaireResult
struct QuestionnaireResult: Codable, Equatable {
    /// The identifier of the [Questionnaire](x-source-tag://Questionnaire) this result belongs to
    let questionnaireUuid: UUID
    var answers: [Answer]
    
    func encode(to encoder: Encoder) throws {
        func isValidAnswerForAPI(_ answer: Answer) -> Bool {
            switch answer.value {
            case .lastExposureDate:
                return false
            default:
                return true
            }
        }
        
        var encodableAnswers: [Answer]
        switch encoder.target {
        case .internalStorage, .unknown:
            encodableAnswers = answers
        case .api:
            encodableAnswers = answers.filter(isValidAnswerForAPI)
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questionnaireUuid, forKey: .questionnaireUuid)
        try container.encode(encodableAnswers, forKey: .answers)
    }
}
