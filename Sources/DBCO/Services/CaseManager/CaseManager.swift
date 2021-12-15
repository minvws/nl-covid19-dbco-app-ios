/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// - Tag: CaseManager
final class CaseManager: CaseManaging, Logging {
    
    private struct Constants {
        static let keychainService = "CaseManager"
        static let normalFetchInterval = TimeInterval(60)
        static let userInitiatedFetchInterval = TimeInterval(10)
    }
    
    private struct ListenerWrapper {
        weak var listener: CaseManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    @Keychain(name: "appData", service: Constants.keychainService, clearOnReinstall: true)
    private var appData: AppData = .empty // swiftlint:disable:this let_var_whitespace
    
    var dataModificationDate: Date? {
        return $appData.modificationDate
    }
    
    var isSynced: Bool {
        return tasks.allSatisfy(\.isSyncedWithPortal)
    }

    @UserDefaults(key: "CaseManager.appData")
    private(set) var hasSynced: Bool = false // swiftlint:disable:this let_var_whitespace
    
    private(set) var tasks: [Task] {
        get { appData.tasks }
        set { appData.tasks = newValue }
    }
    
    private var questionnaires: [Questionnaire] {
        get { appData.questionnaires }
        set { appData.questionnaires = newValue }
    }
    
    private(set) var dateOfSymptomOnset: Date? {
        get { appData.dateOfSymptomOnset }
        set { appData.dateOfSymptomOnset = newValue }
    }
    
    private(set) var dateOfTest: Date? {
        get { appData.dateOfTest }
        set { appData.dateOfTest = newValue }
    }
    
    private(set) var reference: String? {
        get { appData.reference }
        set { appData.reference = newValue }
    }
    
    var startOfContagiousPeriod: Date? {
        let date: Date? = {
            switch (dateOfTest, dateOfSymptomOnset) {
            case (_, .some(let dateOfSymptomOnset)):
                return dateOfSymptomOnset.dateByAddingDays(-2)
            case (.some(let dateOfTest), _):
                return dateOfTest
            default:
                return nil
            }
        }()
        
        return date.map { max($0, Date().dateByAddingDays(-13)) }
    }
    
    private(set) var symptomsKnown: Bool {
        get { appData.symptomsKnown }
        set { appData.symptomsKnown = newValue }
    }
    
    private(set) var symptoms: [String] {
        get { appData.symptoms }
        set { appData.symptoms = newValue }
    }
    
    private(set) var windowExpiresAt: Date {
        get { appData.windowExpiresAt }
        set {
            appData.windowExpiresAt = newValue
            setWindowExpiryTimer()
        }
    }
    
    private var isLocalCase: Bool {
        return !Services.pairingManager.isPaired
    }
    
    var isWindowExpired: Bool {
        return appData.windowExpiresAt.timeIntervalSinceNow < 0
    }
    
    private var windowExpiryTimer: Timer?
    
    var hasCaseData: Bool {
        $appData.exists && !questionnaires.isEmpty
    }
    
    private var fetchDate = Date.distantPast
    
    private func shouldLoadTasks(userInitiated: Bool) -> Bool {
        guard !isLocalCase else { return false }
        guard !isWindowExpired else { return false }
        
        if appData.tasks.isEmpty {
            return true
        } else if userInitiated {
            return fetchDate.timeIntervalSinceNow + Constants.userInitiatedFetchInterval < 0
        } else {
            return fetchDate.timeIntervalSinceNow + Constants.normalFetchInterval < 0
        }
    }
    
    private var shouldLoadQuestionnaires: Bool {
        return appData.questionnaires.isEmpty
    }
    
    func loadCaseData(userInitiated: Bool, completion: @escaping (Bool, CaseManagingError?) -> Void) {
        loadTasksIfNeeded(userInitiated: userInitiated, completion: completion)
    }
    
    private func reinterpretAsGMT0(_ date: Date) -> Date {
        // During onboarding date calculations are in the user's current timezone.
        // We need to reinterpret them as being in GMT+00
        let offset = TimeInterval(TimeZone.current.secondsFromGMT())
        return date.addingTimeInterval(offset)
    }
    
    func startLocalCaseIfNeeded(dateOfSymptomOnset: Date) {
        if !hasCaseData {
            windowExpiresAt = .distantFuture
        }
        
        self.dateOfSymptomOnset = reinterpretAsGMT0(dateOfSymptomOnset)
        appData.symptomsKnown = true
    }
    
    func startLocalCaseIfNeeded(dateOfTest: Date) {
        if !hasCaseData {
            windowExpiresAt = .distantFuture
        }
        
        self.dateOfTest = reinterpretAsGMT0(dateOfTest)
        appData.symptomsKnown = true
    }
    
    func removeCaseData() throws {
        $appData.clearData()
        hasSynced = false
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
        self.questionnaires = questionnaires.map(Self.prepareQuestionnaire)
    }
    
    /// Set the tasks from the api call result
    ///
    /// Updates existing tasks if the user has not yet started them and adds any new tasks
    private func setTasks(_ fetchedTasks: [Task]) {
        let fetchedTasks = fetchedTasks.map { fetchedTask -> Task in
            // Modify the shareIndexNameAlreadyAnswered property for portal tasks
            var task = fetchedTask
            switch task.taskType {
            case .contact:
                task.shareIndexNameAlreadyAnswered = task.contact.canShareIndexNameWithContact != nil
            }
            
            return task
        }
        
        guard !tasks.isEmpty else {
            tasks = fetchedTasks
            return
        }
        
        fetchedTasks.forEach { task in
            if let existingTaskIndex = tasks.firstIndex(where: { $0.uuid == task.uuid }) {
                if tasks[existingTaskIndex].questionnaireResult == nil {
                    // Not modified by the user yet, so we can just replace it entirely
                    tasks[existingTaskIndex] = task
                } else {
                    switch tasks[existingTaskIndex].taskType {
                    case .contact:
                        // Update only the communication type and canShareIndexNameWithContact
                        let existingContact = tasks[existingTaskIndex].contact!
                        tasks[existingTaskIndex].contact = Task.Contact(category: existingContact.category,
                                                                        communication: task.contact.communication,
                                                                        informedByIndexAt: existingContact.informedByIndexAt,
                                                                        dateOfLastExposure: existingContact.dateOfLastExposure,
                                                                        canShareIndexNameWithContact: task.contact.canShareIndexNameWithContact)
                    }
                    
                    tasks[existingTaskIndex].label = task.label
                    tasks[existingTaskIndex].taskContext = task.taskContext
                    tasks[existingTaskIndex].shareIndexNameAlreadyAnswered = task.shareIndexNameAlreadyAnswered
                }
            } else {
                tasks.append(task)
            }
        }
    }
    
    private func setWindowExpiryTimer() {
        guard $appData.exists else { return }
        
        windowExpiryTimer?.invalidate()
        
        guard !isWindowExpired else {
            listeners.forEach { $0.listener?.caseManagerWindowExpired(self) }
            return
        }
        
        windowExpiryTimer = Timer(fire: windowExpiresAt, interval: 0, repeats: false) { [weak self] timer in
            timer.invalidate()
            
            guard let self = self else { return }
            
            self.listeners.forEach { $0.listener?.caseManagerWindowExpired(self) }
        }
        
        RunLoop.main.add(windowExpiryTimer!, forMode: .common)
    }
    
    /// - Tag: CaseManager.questionnaire
    func questionnaire(for taskType: Task.TaskType) throws -> Questionnaire {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        
        guard let questionnaire = questionnaires.first(where: { $0.taskType == taskType }) else {
            logError("Could not find applicable questionnaire")
            throw CaseManagingError.questionnaireNotFound
        }
        
        return questionnaire
    }
    
    private func questionnaireResult(for task: Task, currentTask: Task, questionnaire: Questionnaire) -> QuestionnaireResult {
        let currentAnswers = currentTask.questionnaireResult?.answers ?? []
        let newAnswers = task.questionnaireResult?.answers ?? []
        
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
            .filter { $0.relevantForCategories.contains(task.contact.category) }
            .map(answerForQuestion)
        
        return QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: answers)
    }
    
    func save(_ task: Task) throws {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        
        let wasSynced = isSynced
        let questionnaire = try self.questionnaire(for: task.taskType)
        
        func storeNewTask() -> Int {
            tasks.append(task)
            return tasks.count - 1
        }
        
        let index = tasks.lastIndex { $0.uuid == task.uuid } ?? storeNewTask()
        
        var updatedTask = tasks[index]
        
        // Update task results
        updatedTask.questionnaireResult = questionnaireResult(for: task, currentTask: tasks[index], questionnaire: questionnaire)
        
        // Update task type content
        switch updatedTask.taskType {
        case .contact:
            updatedTask.contact = task.contact
            
            // If it is a task created in the app, update the label with the name
            if tasks[index].source == .app {
                let contactName = task.contactNameAnswer ?? .taskContactUnknownName
                updatedTask.label = contactName
            }
        }
        
        // Update deletion
        updatedTask.deletedByIndex = updatedTask.deletedByIndex || task.deletedByIndex
    
        // Update task if needed and set sync state
        if tasks[index] != updatedTask {
            tasks[index] = updatedTask
            tasks[index].isSyncedWithPortal = false
        }
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
        
        if wasSynced != isSynced {
            listeners.forEach { $0.listener?.caseManagerDidUpdateSyncState(self) }
        }
    }
    
    private static let valueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    func addContactTask(name: String, category: Task.Contact.Category, contactIdentifier: String?, dateOfLastExposure: Date?) {
        var task = Task(type: .contact, label: name, source: .app)
        task.contact = Task.Contact(category: category,
                                    communication: .unknown,
                                    informedByIndexAt: nil,
                                    dateOfLastExposure: dateOfLastExposure.map(Self.valueDateFormatter.string),
                                    canShareIndexNameWithContact: nil,
                                    contactIdentifier: contactIdentifier)
        tasks.append(task)
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
    }
    
    func setSymptoms(symptoms: [String]) {
        self.symptoms = symptoms
    }
    
    func addListener(_ listener: CaseManagerListener) {
        listeners.append(ListenerWrapper(listener: listener))
        
        if isWindowExpired {
            // call listener immediately for expired window
            listener.caseManagerWindowExpired(self)
        } else {
            setWindowExpiryTimer()
        }
    }
    
    private func markAllTasksAsSynced() {
        for index in 0 ..< tasks.count {
            tasks[index].isSyncedWithPortal = true
            
            switch tasks[index].taskType {
            case .contact:
                // If `canShareIndexNameWithContact` was not yet set, but has a value now, mark `shareIndexNameAlreadyAnswered` as true
                if tasks[index].shareIndexNameAlreadyAnswered == false,
                   tasks[index].contact.canShareIndexNameWithContact != nil {
                    tasks[index].shareIndexNameAlreadyAnswered = true
                }
            }
        }
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
    }
    
    func sync(completionHandler: ((Bool) -> Void)?) throws {
        guard hasCaseData else { throw CaseManagingError.noCaseData }
        guard !isWindowExpired else { throw CaseManagingError.windowExpired }
        
        let identifier: String
        
        do {
            identifier = try Services.pairingManager.caseToken()
        } catch let error {
            completionHandler?(false)
            throw error
        }
        
        Services.networkManager.putCase(identifier: identifier, value: appData.asCase) {
            switch $0 {
            case .success:
                self.markAllTasksAsSynced()
                self.hasSynced = true
                completionHandler?(true)
            case .failure(let error):
                self.logError("Could not sync case: \(error)")
                completionHandler?(false)
            }
        }
    }
    
}

extension CaseManager {
    static func prepareQuestionnaire(_ questionnaire: Questionnaire) -> Questionnaire {
        switch questionnaire.taskType {
        case .contact:
            var questions = questionnaire.questions
            
            // Modify the classification questions to be disabled when the task source is .portal
            func shouldBeDisabledForPortalTasks(_ offset: Int, _ question: Question) -> Bool {
                return question.questionType == .classificationDetails
            }
            
            let classificationIndices = questionnaire.questions
                .enumerated()
                .filter(shouldBeDisabledForPortalTasks)
                .map { $0.offset }
            
            for index in classificationIndices {
                questions[index] = questions[index].disabledForPortal
            }
            
            // Insert a .lastExposureDate question
            let lastExposureQuestion = Question.lastExposureDateQuestion
            
            if questions.isEmpty { // Just to be safe
                questions.append(lastExposureQuestion)
            } else {
                questions.insert(lastExposureQuestion, at: 0)
            }
            
            return Questionnaire(uuid: questionnaire.uuid,
                                 taskType: questionnaire.taskType,
                                 questions: questions)
        }
    }
}

// MARK: - Loading
extension CaseManager {
    private func loadTasksIfNeeded(userInitiated: Bool, completion: @escaping (Bool, CaseManagingError?) -> Void) {
        guard shouldLoadTasks(userInitiated: userInitiated) else {
            logDebug("No task loading needed. Skipping.")
            return loadQuestionnairesIfNeeded(completion: completion)
        }
        
        guard let identifier = try? Services.pairingManager.caseToken() else {
            return completion(false, .noCaseData)
        }
        
        let previousFetchDate = fetchDate
        fetchDate = Date() // Set the fetchdate here to prevent multiple request
        
        Services.networkManager.getCase(identifier: identifier) {
            switch $0 {
            case .success(let result):
                self.handleCaseResult(result, completion: completion)
            case .failure(let error):
                self.fetchDate = previousFetchDate // Reset the fetchdate since no data was fetched
                
                completion(false, .couldNotLoadTasks(error))
            }
        }
    }
    
    private func handleCaseResult(_ result: Case, completion: @escaping (Bool, CaseManagingError?) -> Void) {
        setTasks(result.tasks)
        appData.update(with: result)
        fetchDate = Date() // Set the fetchdate here again to the actual date

        loadQuestionnairesIfNeeded(completion: completion)
        
        listeners.forEach { $0.listener?.caseManagerDidUpdateTasks(self) }
    }
    
    private func loadQuestionnairesIfNeeded(completion: @escaping (Bool, CaseManagingError?) -> Void) {
        guard shouldLoadQuestionnaires else {
            logDebug("No questionnaire loading needed. Skipping.")
            return completion(true, nil)
        }
        
        Services.networkManager.getQuestionnaires {
            switch $0 {
            case .success(let questionnaires):
                self.setQuestionnaires(questionnaires)
                
                completion(true, nil)
            case .failure(let error):
                completion(false, .couldNotLoadQuestionnaires(error))
            }
        }
    }
}

private extension Question {
    static var lastExposureDateQuestion: Question {
        return Question(uuid: UUID(),
                        group: .classification,
                        questionType: .lastExposureDate,
                        label: .contactInformationLastExposure,
                        description: nil,
                        relevantForCategories: [.category1, .category2a, .category2b, .category3a, .category3b, .other],
                        answerOptions: nil,
                        disabledForSources: [.portal])
    }
    
    var disabledForPortal: Question {
        return Question(uuid: uuid,
                        group: group,
                        questionType: questionType,
                        label: label,
                        description: description,
                        relevantForCategories: relevantForCategories,
                        answerOptions: answerOptions,
                        disabledForSources: [.portal])
    }
}
