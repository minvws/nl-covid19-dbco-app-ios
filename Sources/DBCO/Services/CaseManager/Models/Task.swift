/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Represents an item on the user's "grocery list".
/// Tasks are completed by filling out an associated [Questionnaire](x-source-tag://Questionnaire).
/// Currently only the `contact` task is supported.
///
/// # See also:
/// [CaseManager](x-source-tag://CaseManager)
///
/// - Tag: Task
struct Task: Equatable {
    enum Status: Equatable {
        case notStarted
        case inProgress(Double)
        case completed
    }
    
    enum Source: String, Codable {
        case app
        case portal
    }
    
    enum TaskType: String, Codable {
        case contact
    }
    
    /// - Tag: Task.Contact
    struct Contact: Equatable {
        
        /// # See also
        /// [ClassificationHelper](x-source-tag://ClassificationHelper)
        ///
        /// - Tag: Task.Contact.Category
        enum Category: String, Codable {
            case category1 = "1"
            case category2a = "2a"
            case category2b = "2b"
            case category3 = "3"
            case other = "other"
        }
        
        enum Communication: String, Codable {
            case staff
            case index
            case none
        }
        
        let category: Category
        let communication: Communication
        let didInform: Bool
        let dateOfLastExposure: String?
        
        init(category: Category, communication: Communication, didInform: Bool, dateOfLastExposure: String?) {
            self.category = category
            self.communication = communication
            self.didInform = didInform
            self.dateOfLastExposure = dateOfLastExposure
        }
    }
    
    let uuid: UUID
    let taskType: TaskType
    let source: Source
    let label: String?
    let taskContext: String?
    
    var contact: Contact!
    
    var deletedByIndex: Bool
    
    var questionnaireResult: QuestionnaireResult?
    
    /// - Tag: Task.status
    var status: Status {
        guard !deletedByIndex else { return .completed }
        
        switch taskType {
        case .contact:
            if let questionnaireProgress = questionnaireResult?.progress {
                // task progress = questionnaire progress * 0.9 + isOrCanBeInformed * 0.1
                let progress = (questionnaireProgress * 0.9) + (isOrCanBeInformed ? 0.1 : 0.0)
                return abs(progress - 1) < 0.01 ? .completed : .inProgress(progress)
            } else {
                return .notStarted
            }
        }
    }
    
    init(type: TaskType) {
        self.uuid = UUID()
        self.taskType = type
        self.source = .app
        self.label = nil
        self.taskContext = nil
        self.deletedByIndex = false
        
        switch taskType {
        case .contact:
            contact = Contact(category: .other, communication: .none, didInform: false, dateOfLastExposure: nil)
        }
    }
    
}

extension Task.Contact: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        category = try container.decode(Category.self, forKey: .category)
        communication = try container.decode(Communication.self, forKey: .communication)
        dateOfLastExposure = try container.decode(String?.self, forKey: .dateOfLastExposure)
        didInform = (try? container.decode(Bool?.self, forKey: .didInform)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(category, forKey: .category)
        try container.encode(communication, forKey: .communication)
        try container.encode(dateOfLastExposure, forKey: .dateOfLastExposure)
        try container.encode(didInform, forKey: .didInform)
    }
    
    private enum CodingKeys: String, CodingKey {
        case category
        case communication
        case dateOfLastExposure
        case didInform
    }
    
}

extension Task: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        source = try container.decode(Source.self, forKey: .source)
        label = try container.decode(String?.self, forKey: .label)
        taskContext = try container.decode(String?.self, forKey: .taskContext)
        questionnaireResult = try? container.decode(QuestionnaireResult?.self, forKey: .questionnaireResult)
        
        taskType = try container.decode(TaskType.self, forKey: .taskType)
        
        switch taskType {
        case .contact:
            contact = try Contact(from: decoder)
        }
        
        deletedByIndex = (try? container.decode(Bool?.self, forKey: .deletedByIndex)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(source, forKey: .source)
        try container.encode(label, forKey: .label)
        try container.encode(taskContext, forKey: .taskContext)
        try container.encode(taskType, forKey: .taskType)
        try container.encode(deletedByIndex, forKey: .deletedByIndex)
        
        switch taskType {
        case .contact:
            try contact?.encode(to: encoder)
        }
        
        // Don't encode result data for deleted tasks when sending to the api
        guard !(encoder.target == .api && deletedByIndex) else { return }
        
        try container.encode(questionnaireResult, forKey: .questionnaireResult)
    }
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case source
        case label
        case taskContext
        case taskType
        case category
        case communication
        case dateOfLastExposure
        case didInform
        case questionnaireResult
        case deletedByIndex
    }
}

extension Task {
    static var emptyContactTask: Task {
        
        var task = Task(type: .contact)
        
        guard let questionnaire = try? Services.caseManager.questionnaire(for: task.taskType) else { return task }
        
        guard let classificationUuid = questionnaire.questions.first(where: { $0.questionType == .classificationDetails })?.uuid else {
            return task
        }
        
        task.questionnaireResult = QuestionnaireResult(questionnaireUuid: questionnaire.uuid,
                                          answers: [
                                            Answer(uuid: UUID(),
                                                   questionUuid: classificationUuid,
                                                   lastModified: Date(),
                                                   value: .classificationDetails(category1Risk: nil, category2aRisk: nil, category2bRisk: nil, category3Risk: nil))
                                          ])
        
        return task
    }
}
