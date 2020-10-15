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
        }
        
        enum Communication: String, Codable {
            case staff
            case index
            case none
        }
        
        let category: Category
        let communication: Communication
    }
    
    let uuid: UUID
    let taskType: TaskType
    let source: Source
    let label: String?
    let taskContext: String?
    
    let contact: Contact!
    
    var result: QuestionnaireResult?
    var status: Status {
        if let progress = result?.progress {
            return progress == 1 ? .completed : .inProgress(progress)
        } else {
            return .notStarted
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
