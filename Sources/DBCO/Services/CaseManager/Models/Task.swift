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
        case missingEssentialInput
        case indexShouldInform
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
        enum Category: String, Codable, CaseIterable {
            case category1 = "1"
            case category2a = "2a"
            case category2b = "2b"
            case category3a = "3a"
            case category3b = "3b"
            case other = "other"
        }
        
        enum Communication: String, Codable {
            case staff
            case index
            case unknown
        }
        
        let category: Category
        let communication: Communication
        let informedByIndexAt: String?
        let dateOfLastExposure: String?
        let shareIndexNameWithContact: Bool?
        let contactIdentifier: String?
        
        /// If the informedByIndexAt field is set to the value of this static field, it Indicates that the index chose not to inform the contact.
        /// This is not communicated to the API, it is used internally only
        ///
        /// # See also
        /// [Filter implementation](x-source-tag://Task.Contact.indexWontInformIndicator.filter)
        ///
        /// - Tag: Task.Contact.indexWontInformIndicator
        static let indexWontInformIndicator: String = "index-wont-inform"
        
        init(category: Category, communication: Communication, informedByIndexAt: String?, dateOfLastExposure: String?, shareIndexNameWithContact: Bool?, contactIdentifier: String? = nil) {
            self.category = category
            self.communication = communication
            self.informedByIndexAt = informedByIndexAt
            self.dateOfLastExposure = dateOfLastExposure
            self.shareIndexNameWithContact = shareIndexNameWithContact
            self.contactIdentifier = contactIdentifier
        }
    }
    
    let uuid: UUID
    let taskType: TaskType
    let source: Source
    var label: String?
    var taskContext: String?
    
    var contact: Contact!
    
    var deletedByIndex: Bool
    
    var questionnaireResult: QuestionnaireResult?
    
    var isSyncedWithPortal: Bool
    var shareIndexNameAlreadyAnswered: Bool
    
    /// - Tag: Task.status
    var status: Status {
        guard !deletedByIndex else { return .completed }
        
        switch taskType {
        case .contact:
            guard let result = questionnaireResult, result.hasAllEssentialAnswers else {
                return .missingEssentialInput
            }
            
            if [.index, .unknown].contains(contact.communication), contact.informedByIndexAt == nil {
                return .indexShouldInform
            } else if isOrCanBeInformed == false {
                return .missingEssentialInput
            }
            
            let completedElements = result.progressElements.filter { $0 }
            
            let progress = Double(completedElements.count) / Double(result.progressElements.count)
            return abs(progress - 1) < 0.01 ? .completed : .inProgress(progress)
        }
    }
    
    init(type: TaskType, label: String? = nil, source: Source = .app) {
        self.uuid = UUID()
        self.taskType = type
        self.source = source
        self.label = label
        self.taskContext = nil
        self.deletedByIndex = false
        self.isSyncedWithPortal = false
        self.shareIndexNameAlreadyAnswered = false
        
        switch taskType {
        case .contact:
            contact = Contact(category: .other, communication: .unknown, informedByIndexAt: nil, dateOfLastExposure: nil, shareIndexNameWithContact: nil, contactIdentifier: nil)
        }
    }
    
}

extension Task.Contact: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        category = try container.decode(Category.self, forKey: .category)
        communication = try container.decode(Communication.self, forKey: .communication)
        dateOfLastExposure = try container.decode(String?.self, forKey: .dateOfLastExposure)
        informedByIndexAt = try container.decodeIfPresent(String.self, forKey: .informedByIndexAt)
        shareIndexNameWithContact = try container.decodeIfPresent(Bool.self, forKey: .shareIndexNameWithContact)
        contactIdentifier = try? container.decode(String?.self, forKey: .contactIdentifier)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var category: Category? = self.category
        var communication: Communication? = self.communication
        
        if encoder.target == .api {
            // Send category "other" as "null" to API
            if category == .other {
                category = nil
            }
            
            // Send communication "unknown" as "null" to API
            if communication == .unknown {
                communication = nil
            }
        }
        
        try container.encode(category, forKey: .category)
        try container.encode(communication, forKey: .communication)
        try container.encode(dateOfLastExposure, forKey: .dateOfLastExposure)
        try container.encode(shareIndexNameWithContact, forKey: .shareIndexNameWithContact)
        
        switch encoder.target {
        case .internalStorage:
            try container.encode(contactIdentifier, forKey: .contactIdentifier)
            try container.encode(informedByIndexAt, forKey: .informedByIndexAt)
        case .api:
            /// Filter out informedByIndex if it is set to the indexWontInformIndicator
            ///
            /// - Tag: Task.Contact.indexWontInformIndicator.filter
            let informedByIndexAtAPIValue = informedByIndexAt == Self.indexWontInformIndicator ? nil : informedByIndexAt
            try container.encode(informedByIndexAtAPIValue, forKey: .informedByIndexAt)
        case .unknown:
            break
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case category
        case communication
        case dateOfLastExposure
        case informedByIndexAt
        case shareIndexNameWithContact
        case contactIdentifier
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
        isSyncedWithPortal = (try container.decodeIfPresent(Bool.self, forKey: .isSyncedWithPortal)) ?? false
        shareIndexNameAlreadyAnswered = (try container.decodeIfPresent(Bool.self, forKey: .shareIndexNameAlreadyAnswered)) ?? false
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
        
        if encoder.target == .internalStorage {
            try container.encode(isSyncedWithPortal, forKey: .isSyncedWithPortal)
            try container.encode(shareIndexNameAlreadyAnswered, forKey: .shareIndexNameAlreadyAnswered)
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
        case dateOfLastExposure
        case didInform
        case questionnaireResult
        case deletedByIndex
        case isSyncedWithPortal
        case shareIndexNameAlreadyAnswered
    }
}

extension Task: Comparable {
    static func < (lhs: Task, rhs: Task) -> Bool {
        guard lhs.taskType == .contact && rhs.taskType == .contact else {
            return false // To be adjusted whenever more taskTypes are added
        }
        
        // category1 before anything else
        if lhs.contact.category == .category1 && rhs.contact.category != .category1 {
            return true
        } else if rhs.contact.category == .category1 && lhs.contact.category != .category1 {
            return false
        }
        
        let fallbackDate = "9999-12-31"
        let leftDate = lhs.contact.dateOfLastExposure ?? fallbackDate
        let rightDate = rhs.contact.dateOfLastExposure ?? fallbackDate
        
        // sort by date
        switch leftDate.compare(rightDate, options: .numeric) {
        case .orderedDescending:
            return true
        case .orderedAscending:
            return false
        case .orderedSame:
            // sort alphabetically for same date
            return (lhs.contactName ?? "") < (rhs.contactName ?? "")
        }
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
                                                   value: .classificationDetails(nil))
                                          ])
        
        return task
    }

}
