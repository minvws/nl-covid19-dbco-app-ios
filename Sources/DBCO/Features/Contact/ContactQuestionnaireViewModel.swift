/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

private extension Question {
    func isRelevant(in category: Task.Contact.Category) -> Bool {
        relevantForCategories.contains(category) || questionType == .classificationDetails
    }
}

private extension Task.Contact {
    var shouldBeDeleted: Bool {
        category == .other ||
        dateOfLastExposure == AnswerOption.lastExposureDateEarlierOption.value
    }
}

private extension Guidelines.Categories {
    func text(for category: Task.Contact.Category) -> String {
        switch category {
        case .category1:
            return category1
        case .category2a, .category2b:
            return category2
        case .category3a, .category3b:
            return category3
        case .other:
            return ""
        }
    }
}

private extension Guidelines.RangedCategories {
    func text(for category: Task.Contact.Category, withinRange: Bool) -> String {
        switch category {
        case .category1:
            return category1
        case .category2a, .category2b:
            if withinRange {
                return category2.withinRange
            } else {
                return category2.outsideRange
            }
        case .category3a, .category3b:
            return category3
        case .other:
            return ""
        }
    }
}

/// The ViewModel required for [ContactQuestionnaireViewController](x-source-tag://ContactQuestionnaireViewController).
/// Can be used to update a task or to create a new task.
///
/// Uses the global [CaseManager](x-source-tag://CaseManaging) to get the appropriate questionnaire. For each question in the questionnaire a class conforming to [AnswerManaging](x-source-tag://AnswerManaging) is created to manage answers, prefilling the answer when possible.
///
/// Only questions needed for the task's category are displayed. A [Question](x-source-tag://Question) with type `.classificationDetails` can update the managed task's category, so displayed questions are highly dynamic.
///
/// - Tag: ContactQuestionnaireViewModel
class ContactQuestionnaireViewModel {
    private var task: Task
    private var baseResult: QuestionnaireResult
    private var updatedClassification: ClassificationHelper.Result
    private var updatedContact: Task.Contact { didSet { updateProgress() } }

    let didCreateNewTask: Bool
    let isDisabled: Bool
    var contactShouldBeDeleted: Bool {
        return updatedTask.contact.shouldBeDeleted
    }
    
    struct Input {
        let caseReference: String?
        let guidelines: Guidelines
        let featureFlags: FeatureFlags
        let isCaseWindowExpired: Bool
        let task: Task?
        let questionnaire: Questionnaire
        let contact: CNContact?
    }
    
    private let input: Input
    
    var updatedTask: Task {
        let updatedCategory = updatedClassification.category ?? task.contact.category
        
        var updatedTask = task
        updatedTask.contact = Task.Contact(category: updatedCategory,
                                           communication: updatedContact.communication,
                                           informedByIndexAt: updatedContact.informedByIndexAt,
                                           dateOfLastExposure: updatedContact.dateOfLastExposure,
                                           shareIndexNameWithContact: updatedContact.shareIndexNameWithContact)
        updatedTask.questionnaireResult = baseResult
        updatedTask.questionnaireResult?.answers = answerManagers
            .filter { $0.question.isRelevant(in: updatedCategory) }
            .map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    
    private(set) var answerManagers: [AnswerManaging]
    
    var canSafelyCancel: Bool {
        guard !isDisabled else { return true }
        
        if updatedTask.contact.category == .other && updatedTask.contact.dateOfLastExposure == nil {
            return true
        }
        return updatedTask == task
    }
    
    private(set) var showDeleteButton: Bool = false
    
    // swiftlint:disable opening_brace
    weak var classificationSectionView: SectionView?    { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var detailsSectionView: SectionView?           { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var informSectionView: SectionView?            { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    // swiftlint:enable opening_brace
    
    @Bindable private(set) var informTitle: String = ""
    @Bindable private(set) var informIntro: String = ""
    @Bindable private(set) var informContent: String = ""
    @Bindable private(set) var informLink: String = ""
    @Bindable private(set) var informFooter: String = ""
    @Bindable private(set) var informButtonTitle: String = ""
    @Bindable private(set) var informButtonHidden: Bool = true
    @Bindable private(set) var copyButtonHidden: Bool = true
    @Bindable private(set) var informButtonType: Button.ButtonType = .secondary
    @Bindable private(set) var copyButtonType: Button.ButtonType = .secondary
    @Bindable private(set) var promptButtonType: Button.ButtonType = .primary
    @Bindable private(set) var promptButtonTitle: String = .save
    
    init(_ input: Input) {
        self.input = input
        self.didCreateNewTask = input.task == nil
        
        let initialCategory = input.task?.contact.category
        let task = input.task ?? Task.emptyContactTask
        self.task = task
        self.updatedContact = task.contact
        self.title = task.contactName ?? .contactFallbackTitle
        
        let questionsAndAnswers: [(question: Question, answer: Answer)] = {
            let currentAnswers = task.questionnaireResult?.answers ?? []
            
            return input.questionnaire.questions.map { question in
                (question, currentAnswers.first { $0.questionUuid == question.uuid } ?? question.emptyAnswer)
            }
        }()
        
        self.baseResult = QuestionnaireResult(questionnaireUuid: input.questionnaire.uuid, answers: questionsAndAnswers.map(\.answer))
        
        self.answerManagers = Self.createAnswerManagers(for: questionsAndAnswers,
                                                        contact: input.contact,
                                                        category: initialCategory,
                                                        dateOfLastExposure: updatedContact.dateOfLastExposure,
                                                        source: task.source)
        self.updatedClassification = .success(task.contact.category)
        self.isDisabled = input.isCaseWindowExpired
        
        setupUpdateHandlers()
        setupInitialState()
    }
    
    private static func createAnswerManagers(for questionsAndAnswers: [(question: Question, answer: Answer)],
                                             contact: CNContact?,
                                             category: Task.Contact.Category?,
                                             dateOfLastExposure: String?,
                                             source: Task.Source) -> [AnswerManaging] {
        return questionsAndAnswers.compactMap { question, answer in
            let manager: AnswerManaging
            
            switch answer.value {
            case .classificationDetails:
                manager = ClassificationDetailsAnswerManager(question: question, answer: answer, contactCategory: category)
            case .contactDetails:
                manager = ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .contactDetailsFull:
                manager = ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .date:
                manager = DateAnswerManager(question: question, answer: answer)
            case .open:
                manager = OpenAnswerManager(question: question, answer: answer)
            case .multipleChoice:
                manager = MultipleChoiceAnswerManager(question: question, answer: answer)
            case .lastExposureDate:
                manager = LastExposureDateAnswerManager(question: question, answer: answer, lastExposureDate: dateOfLastExposure)
            }
            
            manager.isEnabled = !question.disabledForSources.contains(source)
            
            return manager
        }
    }
    
    private func setupUpdateHandlers() {
        answerManagers.forEach {
            $0.updateHandler = { [unowned self] manager in
                switch manager {
                case let classificationManager as ClassificationDetailsAnswerManager:
                    updateClassification(with: classificationManager.classification)
                case let lastExposureManager as LastExposureDateAnswerManager:
                    updateLastExposureDate(with: lastExposureManager.options.value)
                default:
                    break
                }
                
                setupTriggerHandlers(for: manager)
                updateProgress()
            }
        }
    }
    
    private func setupTriggerHandlers(for answerManager: AnswerManaging) {
        if case .multipleChoice(let option) = answerManager.answer.value, let trigger = option?.trigger {
            switch trigger {
            case .setShareIndexNameToYes: setShareIndexNameToYes()
            case .setShareIndexNameToNo: setShareIndexNameToNo()
            }
        }
    }
    
    private func setupInitialState() {
        title = updatedTask.contactName ?? .contactFallbackTitle
        
        updateInformSectionContent()
        
        if isDisabled {
            answerManagers.forEach {
                $0.isEnabled = false
            }
        } else {
            showDeleteButton = updatedTask.source == .app && !didCreateNewTask
        }
    }
    
    private func setShareIndexNameToYes() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: updatedContact.informedByIndexAt,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure,
                                      shareIndexNameWithContact: true)
    }

    private func setShareIndexNameToNo() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: updatedContact.informedByIndexAt,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure,
                                      shareIndexNameWithContact: false)
    }
    
    func registerDidInform() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: ISO8601DateFormatter().string(from: Date()),
                                      dateOfLastExposure: updatedContact.dateOfLastExposure,
                                      shareIndexNameWithContact: updatedContact.shareIndexNameWithContact)
    }
    
    func registerWontInform() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: Task.Contact.indexWontInformIndicator,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure,
                                      shareIndexNameWithContact: updatedContact.shareIndexNameWithContact)
    }
    
    private func updateClassification(with result: ClassificationHelper.Result) {
        updatedClassification = result
        
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = result {
            taskCategory = updatedCategory
            updatedContact = Task.Contact(category: taskCategory,
                                          communication: updatedContact.communication,
                                          informedByIndexAt: updatedContact.informedByIndexAt,
                                          dateOfLastExposure: updatedContact.dateOfLastExposure,
                                          shareIndexNameWithContact: updatedContact.shareIndexNameWithContact)
            
            let lastExposureManager = classificationManagers.first { $0.question.questionType == .lastExposureDate }
            lastExposureManager?.isEnabled = taskCategory != .other
        }
        
        answerManagers.forEach {
            $0.view.isHidden = !$0.question.isRelevant(in: taskCategory) || !$0.isEnabled
        }
        
        updateInformSectionContent()
    }
    
    private func updateLastExposureDate(with value: String?) {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: updatedContact.informedByIndexAt,
                                      dateOfLastExposure: value,
                                      shareIndexNameWithContact: updatedContact.shareIndexNameWithContact)
        
        let classificationDetailsManager = classificationManagers.first { $0.question.questionType == .classificationDetails }
        classificationDetailsManager?.view.isHidden = value == AnswerOption.lastExposureDateEarlierOption.value
        
        updateInformSectionContent()
    }
    
    private var relevantManagers: [AnswerManaging] {
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = updatedClassification {
            taskCategory = updatedCategory
        }
        
        return answerManagers.filter { $0.question.isRelevant(in: taskCategory) }
    }
    
    private var classificationManagers: [AnswerManaging] {
        return relevantManagers.filter { $0.question.group == .classification }
    }
    
    private var contactDetailsManagers: [AnswerManaging] {
        return relevantManagers.filter { $0.question.group == .contactDetails }
    }
    
    private var classificationCompleted: Bool { classificationManagers.essentialsAreCompleted }
    private var detailsCompleted: Bool { contactDetailsManagers.essentialsAreCompleted }
    private var allDetailsFilledIn: Bool { contactDetailsManagers.isFullyCompleted }
    
    private func updateProgress(expandFirstUnfinishedSection: Bool = false) {
        let classificationIsHidden = classificationManagers.allSatisfy { $0.view.isHidden }
        classificationSectionView?.isCompleted = classificationCompleted
        classificationSectionView?.isHidden = classificationIsHidden
        classificationSectionView?.index = 1
        
        let startIndex = classificationIsHidden ? 1 : 2
        detailsSectionView?.index = startIndex
        informSectionView?.index = startIndex + 1
        
        let detailsSectionWasDisabled = detailsSectionView?.isEnabled == false
        let sectionsAreEnabled = classificationManagers.hasValidAnswers && !updatedContact.shouldBeDeleted
        
        detailsSectionView?.isEnabled = sectionsAreEnabled
        informSectionView?.isEnabled = sectionsAreEnabled
        
        detailsSectionView?.isCompleted = detailsCompleted
        informSectionView?.isCompleted = updatedTask.isOrCanBeInformed
        
        let detailsBecameEnabled = detailsSectionWasDisabled && sectionsAreEnabled
        
        if expandFirstUnfinishedSection {
            self.expandFirstUnfinishedSection()
        } else if detailsBecameEnabled {
            detailsSectionView?.expand(animated: true)
            informSectionView?.expand(animated: true)
        }
        
        updateInformSectionContent()
    }
    
    private func expandFirstUnfinishedSection() {
        let sections = [classificationSectionView, detailsSectionView, informSectionView].compactMap { $0 }
        sections.forEach { $0.collapse(animated: false) }
        
        if !classificationCompleted {
            classificationSectionView?.expand(animated: false)
        } else if !allDetailsFilledIn {
            detailsSectionView?.expand(animated: false)
            informSectionView?.expand(animated: false)
        } else {
            informSectionView?.expand(animated: false)
        }
    }
    
    // MARK: - Inform Section Content
    private func setInformButtonTitle(firstName: String?) {
        if updatedTask.contactPhoneNumber != nil && input.featureFlags.enableContactCalling {
            informButtonTitle = .informContactCall(firstName: firstName)
            informButtonHidden = false
        } else {
            informButtonHidden = true
        }
    }
    
    private func updateInformSectionContent() {
        let firstName = updatedTask.contactFirstName
        
        copyButtonHidden = !input.featureFlags.enablePerspectiveCopy
        
        switch updatedContact.communication {
        case .index:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterIndex(firstName: firstName)
        case .staff:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterStaff(firstName: firstName)
        case .unknown:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterUnknown(firstName: firstName)
        }
        
        setInformButtonTitle(firstName: firstName)
        setInformContent()
        
        updateButtonTypes()
    }
    
    private func updateButtonTypes() {
        guard !isDisabled else {
            promptButtonTitle = .close
            promptButtonType = .secondary
            return
        }
        
        guard !updatedContact.shouldBeDeleted else {
            promptButtonType = .secondary
            promptButtonTitle = didCreateNewTask ? .cancel : .close
            return
        }
        
        promptButtonTitle = .save
        
        guard updatedContact.communication == .index else {
            informButtonType = .secondary
            copyButtonType = .secondary
            promptButtonType = .primary
            return
        }
        
        switch (informButtonHidden, copyButtonHidden) {
        case (false, _):
            informButtonType = .primary
            copyButtonType = .secondary
            promptButtonType = .secondary
        case (true, false):
            copyButtonType = .primary
            promptButtonType = .secondary
        case (true, true):
            promptButtonType = .primary
        }
    }
    
    private func setInformContent() {
        let referenceNumber = input.caseReference
        let guidelines = input.guidelines

        var exposureDate: Date?
        
        let introText: String
        let guidelinesText: String
        
        if let dateValue = updatedContact.dateOfLastExposure, let date = LastExposureDateAnswerManager.valueDateFormatter.date(from: dateValue) {
            exposureDate = date
            let isWithin4Days = Date.today.numberOfDaysSince(date) < 4
            
            introText = guidelines.introExposureDateKnown.text(for: updatedContact.category)
            guidelinesText = guidelines.guidelinesExposureDateKnown.text(for: updatedContact.category, withinRange: isWithin4Days)
        } else {
            introText = guidelines.introExposureDateUnknown.text(for: updatedContact.category)
            guidelinesText = guidelines.guidelinesExposureDateUnknown.text(for: updatedContact.category)
        }
        
        let outroText = guidelines.outro.text(for: updatedContact.category)
        
        var referenceNumberItem = referenceNumber != nil ? guidelines.referenceNumberItem : ""
        referenceNumberItem = GuidelinesHelper.parseGuidelines(referenceNumberItem, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: nil)
        
        informContent = GuidelinesHelper.parseGuidelines(guidelinesText, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: referenceNumberItem)
        informIntro = GuidelinesHelper.parseGuidelines(introText, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: referenceNumberItem)
        informLink = GuidelinesHelper.parseGuidelines(outroText, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: referenceNumberItem)
        
        if updatedContact.shouldBeDeleted {
            promptButtonType = .secondary
            promptButtonTitle = didCreateNewTask ? .cancel : .close
        }
    }
    
    var copyableGuidelines: String {
        // Parse the html then return the plaintext string
        let intro = NSAttributedString
            .makeFromHtml(text: informIntro, style: .bodyBlack)
            .string
        
        let content = NSAttributedString
            .makeFromHtml(text: informContent, style: .bodyBlack)
            .string
        
        let link = NSAttributedString
            .makeFromHtml(text: informLink, style: .bodyBlack)
            .string
        
        return [intro, content, link]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
    
    // MARK: - Views
    private func view(manager: AnswerManaging) -> UIView {
        let view = manager.view
        let isRelevant = manager.question.isRelevant(in: task.contact.category)
        let disabledForSource = manager.question.disabledForSources.contains(task.source)
    
        let disabledForAlreadyAnswered: Bool = {
            let isShareIndexNameQuestion = manager.question.answerOptions?.contains { $0.trigger == .setShareIndexNameToYes } == true
            return task.shareIndexNameAlreadyAnswered && isShareIndexNameQuestion
        }()
        
        view.isHidden = !isRelevant || disabledForSource || disabledForAlreadyAnswered
        
        return view
    }
    
    var classificationViews: [UIView] {
        answerManagers
            .filter { $0.question.group == .classification }
            .map(view(manager:))
    }
    
    var contactDetailViews: [UIView] {
        answerManagers
            .filter { $0.question.group == .contactDetails }
            .map(view(manager:))
    }
    
    func setInputFieldDelegate(_ delegate: InputFieldDelegate) {
        answerManagers.forEach { $0.inputFieldDelegate = delegate }
    }
    
}
