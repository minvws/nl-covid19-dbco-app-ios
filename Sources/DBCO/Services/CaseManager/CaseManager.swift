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
    
    var isPaired: Bool { get }
    
    /// Indicates that alls the tasks are uploaded to the backend in their current state
    var isSynced: Bool { get }
    
    var dateOfSymptomOnset: Date { get }
    var tasks: [Task] { get }
    
    var hasUnfinishedTasks: Bool { get }
    
    /// Returns the [Questionnaire](x-source-tag://Questionnaire) associated with a task
    func questionnaire(for task: Task) -> Questionnaire
    
    func loadTasksAndQuestions(pairingCode: String, completion: @escaping (_ success: Bool, _ error: NetworkError?) -> Void)
    
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
    
    private struct Constants {
        static let keychainService = "UserTest-Mocks"
    }
    
    private struct ListenerWrapper {
        weak var listener: CaseManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    @UserDefaults(key: "isSynced")
    private(set) var isSynced: Bool = true {
        didSet {
            listeners.forEach { $0.listener?.caseManagerDidUpdateSyncState(self) }
        }
    }
    
    @Keychain(name: "questionnaires", service: Constants.keychainService)
    private var questionnaires: [Questionnaire] = []
    
    @Keychain(name: "tasks", service: Constants.keychainService)
    private(set) var tasks: [Task] = []
    
    @Keychain(name: "dateOfSymptomOnset", service: Constants.keychainService)
    private(set) var dateOfSymptomOnset: Date = Date()
    
    @UserDefaults(key: "didPair")
    private(set) var didPair: Bool = false
    
    var isPaired: Bool {
        return
            $tasks.exists &&
            $questionnaires.exists &&
            $dateOfSymptomOnset.exists &&
            didPair
    }
    
    var hasUnfinishedTasks: Bool {
        tasks.contains { $0.status != .completed }
    }
    
    func loadTasksAndQuestions(pairingCode: String, completion: @escaping (Bool, NetworkError?) -> Void) {
        // This is all temporary code until until pairing with the API is available.
        
        // Clear existing data
        tasks = []
        questionnaires = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 0.1...0.5)) {
            if let validCodes = Bundle.main.infoDictionary?["ValidCodes"] as? [String] {
                guard validCodes.contains(pairingCode.sha256) else {
                    completion(false, .invalidRequest)
                    return
                }
            }
        
            let group = DispatchGroup()
            
            group.enter()
            Services.networkManager.getCase(identifier: "1234") { result in
                self.tasks = (try? result.get())?.tasks ?? []
                self.dateOfSymptomOnset = (try? result.get())?.dateOfSymptomOnset ?? Date()
                self.listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
                group.leave()
            }
            
            group.enter()
            Services.networkManager.getQuestionnaires { result in
                self.setQuestionnaires((try? result.get()) ?? [])
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.didPair = true
                completion(true, nil)
            }
        }
    }
    
    /// Set the questionnaires from the api call result
    ///
    /// The app injects a question of the `lastExposureDate` in the contact [Questionnaire](x-source-tag://Questionnaire) to support the `dateOfLastExposure` property at the [Task](x-source-tag://Task) level.
    /// Answers to a question with this type should not be sent to the backend.
    ///
    /// # See also
    /// [lastExposureDate](x-source-tag://lastExposureDate)
    ///
    /// - Tag: CaseManager.setQuestionnaires
    private func setQuestionnaires(_ questionnaires: [Questionnaire]) {
        func injectingLastExposureDateIfNeeded(_ questionnaire: Questionnaire) -> Questionnaire {
            switch questionnaire.taskType {
            case .contact:
                var questions = questionnaire.questions
                
                let lastExposureQuestion = Question(uuid: UUID(),
                                                    group: .contactDetails,
                                                    questionType: .lastExposureDate,
                                                    label: .contactInformationLastExposure,
                                                    description: nil,
                                                    relevantForCategories: [.category1, .category2a, .category2b, .category3],
                                                    answerOptions: nil)
                
                // Find the index of the question modifying the communication type. (Via triggers)
                let communicationQuestionIndex = questionnaire.questions
                    .firstIndex { $0.answerOptions?.contains { $0.trigger == .setCommunicationToIndex } == true }
                
                if let index = communicationQuestionIndex {
                    questions.insert(lastExposureQuestion, at: index)
                } else {
                    questions.append(lastExposureQuestion)
                }
                
                return Questionnaire(uuid: questionnaire.uuid,
                                     taskType: questionnaire.taskType,
                                     questions: questions)
            }
        }
        
        self.questionnaires = questionnaires.map(injectingLastExposureDateIfNeeded)
    }
    
    /// - Tag: CaseManager.questionnaire
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
        
        let questionnaire = self.questionnaire(for: task)
        
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
