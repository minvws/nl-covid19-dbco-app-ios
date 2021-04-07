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
    
    var updatedTask: Task {
        let updatedCategory = updatedClassification.category ?? task.contact.category
        
        var updatedTask = task
        updatedTask.contact = Task.Contact(category: updatedCategory,
                                           communication: updatedContact.communication,
                                           informedByIndexAt: updatedContact.informedByIndexAt,
                                           dateOfLastExposure: updatedContact.dateOfLastExposure)
        updatedTask.questionnaireResult = baseResult
        updatedTask.questionnaireResult?.answers = answerManagers
            .filter { $0.question.isRelevant(in: updatedCategory) }
            .map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    
    private(set) var answerManagers: [AnswerManaging]
    
    var canSafelyCancel: Bool {
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
    @Bindable private(set) var promptButtonType: Button.ButtonType = .primary
    @Bindable private(set) var promptButtonTitle: String = .save
    
    init(task: Task?, questionnaire: Questionnaire, contact: CNContact? = nil) {
        self.didCreateNewTask = task == nil
        
        let initialCategory = task?.contact.category
        let task = task ?? Task.emptyContactTask
        self.task = task
        self.updatedContact = task.contact
        self.title = task.contactName ?? .contactFallbackTitle
        
        let questionsAndAnswers: [(question: Question, answer: Answer)] = {
            let currentAnswers = task.questionnaireResult?.answers ?? []
            
            return questionnaire.questions.map { question in
                (question, currentAnswers.first { $0.questionUuid == question.uuid } ?? question.emptyAnswer)
            }
        }()
        
        self.baseResult = QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: questionsAndAnswers.map(\.answer))
        
        self.answerManagers = Self.createAnswerManagers(for: questionsAndAnswers,
                                                        contact: contact,
                                                        category: initialCategory,
                                                        dateOfLastExposure: updatedContact.dateOfLastExposure,
                                                        source: task.source)
        self.updatedClassification = .success(task.contact.category)
        self.isDisabled = Services.caseManager.isWindowExpired
        
        answerManagers.forEach {
            $0.updateHandler = { [unowned self] in
                switch $0 {
                case let classificationManager as ClassificationDetailsAnswerManager:
                    updateClassification(with: classificationManager.classification)
                case let lastExposureManager as LastExposureDateAnswerManager:
                    updateLastExposureDate(with: lastExposureManager.options.value)
                default:
                    break
                }
                
                updateProgress()
            }
        }
        
        self.title = updatedTask.contactName ?? .contactFallbackTitle
        
        updateInformSectionContent()
        
        if isDisabled {
            answerManagers.forEach {
                $0.isEnabled = false
            }
        } else {
            showDeleteButton = updatedTask.source == .app && !didCreateNewTask
        }
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
    
    func registerDidInform() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      informedByIndexAt: ISO8601DateFormatter().string(from: Date()),
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
    }
    
    private func updateClassification(with result: ClassificationHelper.Result) {
        updatedClassification = result
        
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = result {
            taskCategory = updatedCategory
            updatedContact = Task.Contact(category: taskCategory,
                                          communication: updatedContact.communication,
                                          informedByIndexAt: updatedContact.informedByIndexAt,
                                          dateOfLastExposure: updatedContact.dateOfLastExposure)
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
                                      dateOfLastExposure: value)
        
        updateInformSectionContent()
    }
    
    private func updateProgress(expandFirstUnfinishedSection: Bool = false) {
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = updatedClassification {
            taskCategory = updatedCategory
        }
        
        let relevantManagers = answerManagers.filter { $0.question.isRelevant(in: taskCategory) }
        let classificationManagers = relevantManagers.filter { $0.question.group == .classification }
        let contactDetailsManagers = relevantManagers.filter { $0.question.group == .contactDetails }
        
        func isCompleted(_ answer: Answer) -> Bool {
            return answer.progressElements.allSatisfy { $0 }
        }
        
        let classificationCompleted = classificationManagers
            .map(\.answer)
            .filter(\.isEssential)
            .allSatisfy(isCompleted)
        
        let detailsCompleted = contactDetailsManagers
            .map(\.answer)
            .filter(\.isEssential)
            .allSatisfy(isCompleted)
        
        let allDetailsFilledIn = contactDetailsManagers
            .map(\.answer)
            .allSatisfy(isCompleted)
        
        let classificationIsHidden = classificationManagers.allSatisfy { $0.view.isHidden }
        classificationSectionView?.isCompleted = classificationCompleted
        classificationSectionView?.isHidden = classificationIsHidden
        classificationSectionView?.index = 1
        detailsSectionView?.isCompleted = detailsCompleted
        informSectionView?.isCompleted = updatedTask.isOrCanBeInformed
        
        let detailsSectionWasDisabled = detailsSectionView?.isEnabled == false
        detailsSectionView?.isEnabled =
            classificationManagers.allSatisfy(\.hasValidAnswer) &&
            !updatedContact.shouldBeDeleted
        detailsSectionView?.index = classificationIsHidden ? 1 : 2
        
        let informSectionWasDisabled = informSectionView?.isEnabled == false
        informSectionView?.index = classificationIsHidden ? 2 : 3
        informSectionView?.isEnabled =
            classificationManagers.allSatisfy(\.hasValidAnswer) &&
            !updatedContact.shouldBeDeleted
        
        if expandFirstUnfinishedSection {
            let sections = [classificationSectionView, detailsSectionView, informSectionView].compactMap { $0 }
            sections.forEach { $0.collapse(animated: false) }
            
            if !classificationCompleted {
                classificationSectionView?.expand(animated: false)
            } else if !allDetailsFilledIn {
                detailsSectionView?.expand(animated: false)
                if informSectionView?.isEnabled == true { // Since the inform section is not disabled, it wouldn't auto expand otherwise
                    informSectionView?.expand(animated: false)
                }
            } else if sections.allSatisfy(\.isCollapsed) {
                informSectionView?.expand(animated: false)
            }
        } else if detailsSectionWasDisabled && (detailsSectionView?.isEnabled == true) { // Expand details section if it became enabled
            detailsSectionView?.expand(animated: true)
            informSectionView?.expand(animated: true)
            
        } else if informSectionWasDisabled && (informSectionView?.isEnabled == true) { // Expand inform section if it became enabled
            informSectionView?.expand(animated: true)
        }
        
        updateInformSectionContent()
    }
    
    // MARK: - Inform Section Content
    private func setInformButtonTitle(firstName: String?) {
        if updatedTask.contactPhoneNumber != nil && Services.configManager.featureFlags.enableContactCalling {
            informButtonTitle = .informContactCall(firstName: firstName)
            informButtonHidden = false
        } else {
            informButtonHidden = true
        }
    }
    
    struct ExposureDates {
        let exposureDate: String
        let exposureDatePlus5: String
        let exposureDatePlus10: String
        let exposureDatePlus11: String
        let exposureDatePlus14: String
        
        init(exposureDate: Date) {
            let exposureDatePlus5 = exposureDate.dateByAddingDays(5)
            let exposureDatePlus10 = exposureDate.dateByAddingDays(10)
            let exposureDatePlus11 = exposureDate.dateByAddingDays(11)
            let exposureDatePlus14 = exposureDate.dateByAddingDays(14)
            
            let formatter = DateFormatter()
            formatter.dateFormat = .informContactGuidelinesDateFormat
            formatter.calendar = Calendar.current
            formatter.locale = Locale.current
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            self.exposureDate = formatter.string(from: exposureDate)
            self.exposureDatePlus5 = formatter.string(from: exposureDatePlus5)
            self.exposureDatePlus10 = formatter.string(from: exposureDatePlus10)
            self.exposureDatePlus11 = formatter.string(from: exposureDatePlus11)
            self.exposureDatePlus14 = formatter.string(from: exposureDatePlus14)
        }
    }
    
    private func updateInformSectionContent() {
        let firstName = updatedTask.contactFirstName
        
        copyButtonHidden = !Services.configManager.featureFlags.enablePerspectiveCopy
        
        informButtonType = .secondary
        promptButtonType = .primary
        
        switch updatedContact.communication {
        case .index:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterIndex(firstName: firstName)
            informButtonType = .primary
            promptButtonType = .secondary
        case .staff:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterStaff(firstName: firstName)
        case .unknown:
            informTitle = .informContactTitle(firstName: firstName)
            informFooter = .informContactFooterUnknown(firstName: firstName)
        }
        
        setInformButtonTitle(firstName: firstName)
        
        if isDisabled {
            promptButtonTitle = .close
            promptButtonType = .secondary
        } else {
            promptButtonTitle = .save
        }
        
        setInformContent()
    }
    
    private func setInformContent() {
        let reference = Services.caseManager.reference
        
        if let dateValue = updatedContact.dateOfLastExposure,
           let exposureDate = LastExposureDateAnswerManager.valueDateFormatter.date(from: dateValue) {
            
            let dates = ExposureDates(exposureDate: exposureDate)
            let isWithin4Days = Date.today.numberOfDaysSince(exposureDate) < 4
            
            informContent = .informContactGuidelines(category: updatedContact.category,
                                                     exposureDatePlus5: dates.exposureDatePlus5,
                                                     exposureDatePlus10: dates.exposureDatePlus10,
                                                     exposureDatePlus11: dates.exposureDatePlus11,
                                                     exposureDatePlus14: dates.exposureDatePlus14,
                                                     within4Days: isWithin4Days,
                                                     reference: reference)
            informIntro = .informContactGuidelinesIntro(category: updatedContact.category,
                                                        exposureDate: dates.exposureDate)
        } else {
            informContent = .informContactGuidelinesGeneric(category: updatedContact.category,
                                                            reference: reference)
            informIntro = .informContactGuidelinesIntroGeneric(category: updatedContact.category)
        }
        
        if updatedContact.shouldBeDeleted {
            promptButtonType = .secondary
            promptButtonTitle = didCreateNewTask ? .cancel : .close
        }
        
        informLink = .informContactLink(category: updatedTask.contact.category)
    }
    
    var copyableGuidelines: String {
        // Parse the html then return the plaintext string
        let intro = NSAttributedString
            .makeFromHtml(text: informIntro, font: Theme.fonts.body, textColor: .black)
            .string
        
        let content = NSAttributedString
            .makeFromHtml(text: informContent, font: Theme.fonts.body, textColor: .black)
            .string
        
        let link = NSAttributedString
            .makeFromHtml(text: informLink, font: Theme.fonts.body, textColor: .black)
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
        view.isHidden = !isRelevant || disabledForSource
        
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
