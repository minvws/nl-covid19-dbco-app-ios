/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct Task: Codable {
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
    
    struct Contact: Codable {
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
        
        init(category: Category, communication: Communication, didInform: Bool) {
            self.category = category
            self.communication = communication
            self.didInform = didInform
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            category = try container.decode(Category.self, forKey: .category)
            communication = try container.decode(Communication.self, forKey: .communication)
            didInform = false
        }
        
        func encode(to encoder: Encoder) throws {
            try category.encode(to: encoder)
            try communication.encode(to: encoder)
        }
    }
    
    let uuid: UUID
    let taskType: TaskType
    let source: Source
    let label: String?
    let taskContext: String?
    
    var contact: Contact!
    
    var result: QuestionnaireResult?
    
    var status: Status {
        switch taskType {
        case .contact:
            if let questionnaireProgress = result?.progress {
                // task progress = questionnaire progress * 0.9 + didInform * 0.1
                let progress = (questionnaireProgress * 0.9) + (contact.didInform ? 0.1 : 0.0)
                return abs(progress - 1) < 0.01 ? .completed : .inProgress(progress)
            } else {
                return .notStarted
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        source = try container.decode(Source.self, forKey: .source)
        label = try container.decode(String?.self, forKey: .label)
        taskContext = try container.decode(String?.self, forKey: .taskContext)
        
        taskType = try container.decode(TaskType.self, forKey: .taskType)
        
        switch taskType {
        case .contact:
            contact = try Contact(from: decoder)
        }
    }
    
    init(type: TaskType) {
        self.uuid = UUID()
        self.taskType = type
        self.source = .app
        self.label = nil
        self.taskContext = nil
        
        switch taskType {
        case .contact:
            contact = Contact(category: .category3, communication: .none, didInform: false)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try uuid.encode(to: encoder)
        try source.encode(to: encoder)
        try label?.encode(to: encoder)
        try taskContext?.encode(to: encoder)
        try taskType.encode(to: encoder)
        
        switch taskType {
        case .contact:
            try contact.category.encode(to: encoder)
            try contact.communication.encode(to: encoder)
        }
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case source
        case label
        case taskContext
        case taskType
        case category
        case communication
    }
}

extension Task {
    static var emptyContactTask: Task {
        
        var task = Task(type: .contact)
        let questionnaire = Services.taskManager.questionnaire(for: task)
        guard let classificationUuid = questionnaire.questions.first(where: { $0.questionType == .classificationDetails })?.uuid else {
            return task
        }
        
        task.result = QuestionnaireResult(questionnaireUuid: questionnaire.uuid,
                                          answers: [
                                            Answer(uuid: UUID(),
                                                   questionUuid: classificationUuid,
                                                   lastModified: Date(),
                                                   value: .classificationDetails(livedTogetherRisk: nil, durationRisk: nil, distanceRisk: nil, otherRisk: nil))
                                          ])
        
        return task
    }
}
