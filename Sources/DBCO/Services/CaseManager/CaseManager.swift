/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Loads tasks and questionnaires.
/// Facilitates storing and uploading results to the backend.
/// Publishes updates to the internal store via [CaseManagerListener](x-source-tag://CaseManagerListener)
///
/// # See also:
/// [Task](x-source-tag://Task),
/// [Questionnaire](x-source-tag://Questionnaire)
///
/// - Tag: CaseManaging
protocol CaseManaging {
    init()
    
    var tasks: [Task] { get }
    
    /// Indicates that alls the tasks are uploaded to the backend in their current state
    var isSynced: Bool { get }
    
    var hasUnfinishedTasks: Bool { get }
    
    /// Returns the [Questionnaire](x-source-tag://Questionnaire) associated with a task
    func questionnaire(for task: Task) -> Questionnaire
    
    func loadTasksAndQuestions(completion: @escaping () -> Void)
    
    /// Adds a listener
    /// - parameter listener: The object conforming to [CaseManagerListener](x-source-tag://CaseManagerListener) that will receive updates. Will be stored with a weak reference
    func addListener(_ listener: CaseManagerListener)
    
    /// Saves updates to a task if a task with the same uuid is already managed, or stores a new task.
    func save(_ task: Task)
    
    /// Uploads all the tasks to the backend
    /// - parameter completionHandler: The closure to be called after the upload was finished.
    func sync(completionHandler: ((_ success: Bool) -> Void)?)
}

/// - Tag: CaseManagerListener
protocol CaseManagerListener: class {
    /// Called after updates are made to the managed tasks
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging)
    
    /// Called after tasks were uploaded to the backend
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging)
}

// Temporary implementation
/// - Tag: CaseManager
final class CaseManager: CaseManaging, Logging {
    
    private struct ListenerWrapper {
        weak var listener: CaseManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    private(set) var isSynced: Bool = false {
        didSet {
            listeners.forEach { $0.listener?.caseManagerDidUpdateSyncState(self) }
        }
    }
    
    private var questionnaires = [Questionnaire]()
    private(set) var tasks = [Task]()
    
    var hasUnfinishedTasks: Bool {
        tasks.contains { $0.status != .completed }
    }
    
    func loadTasksAndQuestions(completion: @escaping () -> Void) {
        // Temporary implementation
        let group = DispatchGroup()
        
        group.enter()
        Services.networkManager.getTasks(caseIdentifier: "1234") { result in
            self.tasks = (try? result.get()) ?? []
            self.listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
            group.leave()
        }
        
        group.enter()
        Services.networkManager.getQuestionnaires { result in
            self.questionnaires = (try? result.get()) ?? []
            group.leave()
        }
        
        group.notify(queue: .main, execute: completion)
    }
    
    func questionnaire(for task: Task) -> Questionnaire {
        guard let questionnaire = questionnaires.first(where: { $0.taskType == task.taskType }) else {
            logError("Could not find applicable questionnaire")
            fatalError()
        }
        
        return questionnaire
    }
    
    func save(_ task: Task) {
        func storeNewTask() -> Int {
            tasks.append(task)
            return tasks.count - 1
        }
        
        let index = tasks.lastIndex { $0.uuid == task.uuid } ?? storeNewTask()
            
        guard let questionnaire = questionnaires.first(where: { $0.taskType == task.taskType }) else {
            logError("Could not find applicable questionnaire")
            fatalError()
        }
        
        // Update task type content
        switch tasks[index].taskType {
        case .contact:
            tasks[index].contact = task.contact
        }
        
        let currentAnswers = tasks[index].result?.answers ?? []
        let newAnswers = task.result?.answers ?? []
        
        // Ensure we have (empty) answers for all necessary questions
        // Updating existing any answers
        func answerForQuestion(_ question: Question) -> Answer {
            let currentAnswer = currentAnswers.first { $0.questionUuid == question.uuid }
            let newAnswer = newAnswers.first { $0.questionUuid == question.uuid }
            
            switch (currentAnswer, newAnswer) {
            case (.some(let current), .some(let new)):
                let isModified = current.value != new.value
                let modifiedDate = isModified ? Date() : current.lastModified
                return Answer(uuid: current.uuid, questionUuid: question.uuid, lastModified: modifiedDate, value: new.value)
            case (.none, .some(let new)):
                return Answer(uuid: new.uuid, questionUuid: question.uuid, lastModified: Date(), value: new.value)
            case (.some(let current), .none):
                return current
            case (.none, .none):
                return question.emptyAnswer
            }
        }
        
        let answers = questionnaire.questions
            .filter { $0.relevantForCategories.contains(tasks[index].contact.category) }
            .map(answerForQuestion)
        
        tasks[index].result = QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: answers)
        
        isSynced = false
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
    }
    
    func addListener(_ listener: CaseManagerListener) {
        listeners.append(ListenerWrapper(listener: listener))
    }
    
    func sync(completionHandler: ((Bool) -> Void)?) {
        // Fake doing some work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSynced = true
            completionHandler?(true)
        }
    }
    
}
