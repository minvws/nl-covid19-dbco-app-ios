/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol TaskManaging {
    init()
    
    var tasks: [Task] { get }
    var isSynced: Bool { get }
    var hasUnfinishedTasks: Bool { get }
    
    func questionnaire(for task: Task) -> Questionnaire
    func loadTasksAndQuestions(completion: @escaping () -> Void)
    func addListener(_ listener: TaskManagerListener)
    
    func save(_ task: Task)
    func sync(completionHandler: ((Bool) -> Void)?)
}

protocol TaskManagerListener: class {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManaging)
    func taskManagerDidUpdateSyncState(_ taskManager: TaskManaging)
}

// Temporary implementation
final class TaskManager: TaskManaging, Logging {
    
    private struct ListenerWrapper {
        weak var listener: TaskManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    private(set) var isSynced: Bool = false {
        didSet {
            listeners.forEach { $0.listener?.taskManagerDidUpdateSyncState(self) }
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
            self.listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
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
        
        listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
    }
    
    func addListener(_ listener: TaskManagerListener) {
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
