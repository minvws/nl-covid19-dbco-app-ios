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
    
    var updatedTask: Task {
        let updatedCategory = updatedClassification.category ?? task.contact.category
        
        var updatedTask = task
        updatedTask.contact = Task.Contact(category: updatedCategory,
                                           communication: updatedContact.communication,
                                           didInform: updatedContact.didInform,
                                           dateOfLastExposure: updatedContact.dateOfLastExposure)
        updatedTask.result = baseResult
        updatedTask.result?.answers = answerManagers.map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    let showCancelButton: Bool
    
    private var answerManagers: [AnswerManaging]
    
    weak var classificationSectionView: SectionView?    { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var detailsSectionView: SectionView?           { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var informSectionView: SectionView?            {
        didSet {
            updateProgress(expandFirstUnfinishedSection: true)
            updateInformSectionContent()
        }
    }
    
    private var informTitle: String                     { didSet { informTitleHandler?(informTitle) } }
    private var informContent: String                   { didSet { informContentHandler?(informContent) } }
    private var informButtonType: Button.ButtonType     { didSet { informButtonTypeHandler?(informButtonType) } }
    
    var informTitleHandler: ((String) -> Void)?                 { didSet { informTitleHandler?(informTitle) } }
    var informContentHandler: ((String) -> Void)?               { didSet { informContentHandler?(informContent) } }
    var informButtonTypeHandler: ((Button.ButtonType) -> Void)? { didSet { informButtonTypeHandler?(informButtonType) } }
    
    init(task: Task?, contact: CNContact? = nil, showCancelButton: Bool = false) {
        let initialCategory = task?.contact.category
        let task = task ?? Task.emptyContactTask
        self.task = task
        self.updatedContact = task.contact
        self.title = task.contactName ?? .contactFallbackTitle
        self.showCancelButton = showCancelButton
        
        self.informTitle = ""
        self.informContent = ""
        self.informButtonType = .primary
        
        let questionnaire = Services.caseManager.questionnaire(for: task)
        
        let questionsAndAnswers: [(question: Question, answer: Answer)] = {
            let currentAnswers = task.result?.answers ?? []
            
            return questionnaire.questions.map { question in
                (question, currentAnswers.first { $0.questionUuid == question.uuid } ?? question.emptyAnswer)
            }
        }()
        
        self.baseResult = QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: questionsAndAnswers.map(\.answer))
        
        self.answerManagers = []
        self.updatedClassification = .success(task.contact.category)
        
        self.answerManagers = questionsAndAnswers.compactMap { question, answer in
            switch answer.value {
            case .classificationDetails:
                return ClassificationDetailsAnswerManager(question: question, answer: answer, contactCategory: initialCategory)
            case .contactDetails:
                return ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .contactDetailsFull:
                return ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .date:
                return DateAnswerManager(question: question, answer: answer)
            case .open:
                return OpenAnswerManager(question: question, answer: answer)
            case .multipleChoice:
                return MultipleChoiceAnswerManager(question: question, answer: answer, contact: task.contact)
            case .lastExposureDate:
                return LastExposureDateAnswerManager(question: question, answer: answer, lastExposureDate: updatedContact.dateOfLastExposure)
            }
        }
        
        answerManagers.forEach {
            $0.updateHandler = { [unowned self] in
                switch $0 {
                case let classificationManager as ClassificationDetailsAnswerManager:
                    updateClassification(with: classificationManager.classification)
                case let lastExposureManager as LastExposureDateAnswerManager:
                    updateLastExposureDate(with: lastExposureManager.date.dateValue)
                default:
                    break
                }
                
                if case .multipleChoice(let option) = $0.answer.value, let trigger = option?.trigger {
                    switch trigger {
                    case .setCommunicationToIndex: setCommunicationToIndex()
                    case .setCommunicationToStaff: setCommunicationToStaff()
                    }
                }
                
                updateProgress()
            }
        }
        
        self.title = updatedTask.contactName ?? .contactFallbackTitle
        
        updateInformSectionContent()
    }
    
    private func setCommunicationToIndex() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: .index,
                                      didInform: updatedContact.didInform,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
        updateInformSectionContent()
    }
    
    private func setCommunicationToStaff() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: .staff,
                                      didInform: updatedContact.didInform,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
        updateInformSectionContent()
    }
    
    func registerDidInform() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      didInform: true,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
    }
    
    private func updateClassification(with result: ClassificationHelper.Result) {
        updatedClassification = result
        
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = result {
            taskCategory = updatedCategory
            updatedContact = Task.Contact(category: taskCategory,
                                          communication: updatedContact.communication,
                                          didInform: updatedContact.didInform,
                                          dateOfLastExposure: updatedContact.dateOfLastExposure)
        }
        
        answerManagers.forEach {
            $0.view.isHidden = !$0.question.isRelevant(in: taskCategory)
        }
        
        updateInformSectionContent()
    }
    
    private func updateLastExposureDate(with date: Date?) {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      didInform: updatedContact.didInform,
                                      dateOfLastExposure: date)
        
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
        let otherManagers = relevantManagers.filter { $0.question.group == .other }
        
        classificationSectionView?.isCompleted = classificationManagers.allSatisfy(\.hasValidAnswer)
        detailsSectionView?.isCompleted = contactDetailsManagers.allSatisfy(\.hasValidAnswer)
        informSectionView?.isCompleted = otherManagers.allSatisfy(\.hasValidAnswer) && updatedContact.didInform
        
        detailsSectionView?.isEnabled = classificationManagers.allSatisfy(\.hasValidAnswer)
        informSectionView?.isEnabled = classificationManagers.allSatisfy(\.hasValidAnswer)
        
        if expandFirstUnfinishedSection {
            let sections = [classificationSectionView, detailsSectionView, informSectionView].compactMap { $0 }
            sections.forEach { $0.collapse(animated: false) }
            sections.first { !$0.isCompleted }?.expand(animated: false)
        }
    }
    
    private func updateInformSectionContent() {
        switch updatedContact.communication {
        case .index:
            informSectionView?.caption = .informContactSectionMessageIndex
            informTitle = .informContactTitleIndex
            informButtonType = .primary
        case .staff:
            informSectionView?.caption = .informContactSectionMessageStaff
            informTitle = .informContactTitleStaff
            informButtonType = .secondary
        case .none:
            // TODO: https://egeniq.atlassian.net/browse/DBCO-131
            break
        }
        
        switch updatedContact.category {
        case .category1, .category2a, .category2b:
            if let date = updatedContact.dateOfLastExposure {
                let untilDate = date.addingTimeInterval(10 * 24 * 3600) // 10 days
                
                let dateFormatter = DateFormatter()
                dateFormatter.calendar = .current
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                dateFormatter.dateFormat = .informContactGuidelinesCloseDateFormat
                
                let untilDateString = String.informContactGuidelinesCloseUntilDate(date: dateFormatter.string(from: untilDate))
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: Date(), to: untilDate)
                
                var daysRemainingString = ""
                
                if let daysRemaining = components.day {
                    switch daysRemaining {
                    case 1:
                        daysRemainingString = .informContactGuidelinesCloseDayRemaining
                    case 2...:
                        daysRemainingString = .informContactGuidelinesCloseDaysRemaining(daysRemaining: String(daysRemaining))
                    default:
                        daysRemainingString = ""
                    }
                }
                
                informContent = .informContactGuidelinesClose(untilDate: untilDateString,
                                                              daysRemaining: daysRemainingString)
            } else {
                informContent = .informContactGuidelinesClose(untilDate: "", daysRemaining: "")
            }
        case .category3:
            informContent = .informContactGuidelinesOther
        case .other:
            // TODO: https://egeniq.atlassian.net/browse/DBCO-131
            break
        }
    }
    
    private func view(manager: AnswerManaging) -> UIView {
        let view = manager.view
        let isRelevant = manager.question.isRelevant(in: task.contact.category)
        view.isHidden = !isRelevant
        
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
}

protocol ContactQuestionnaireViewControllerDelegate: class {
    func contactQuestionnaireViewControllerDidCancel(_ controller: ContactQuestionnaireViewController)
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, didSave contactTask: Task)
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, wantsToInformContact task: Task, completionHandler: @escaping (_ success: Bool) -> Void)
}

/// Displays a [Questionnaire](x-source-tag://Questionnaire) for a contact task. Groups questions into sections displayed with [SectionView](x-source-tag://SectionView)
///
/// # See also
/// [ContactQuestionnaireViewModel](x-source-tag://ContactQuestionnaireViewModel)
///
/// - Tag: ContactQuestionnaireViewController
final class ContactQuestionnaireViewController: PromptableViewController {
    private let viewModel: ContactQuestionnaireViewModel
    private var scrollView: UIScrollView!
    
    weak var delegate: ContactQuestionnaireViewControllerDelegate?
    
    init(viewModel: ContactQuestionnaireViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = viewModel.title
        
        if viewModel.showCancelButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        }
        
        promptView = Button(title: .save)
            .touchUpInside(self, action: #selector(save))
        
        // Type
        let classificationSectionView = SectionView(title: .contactTypeSectionTitle, caption: .contactTypeSectionMessage, index: 1)
        classificationSectionView.expand(animated: false)
        
        VStack(spacing: 24, viewModel.classificationViews)
            .embed(in: classificationSectionView.contentView.readableWidth)
        
        // Details
        let contactDetailsSection = SectionView(title: .contactDetailsSectionTitle, caption: .contactDetailsSectionMessage, index: 2)
        contactDetailsSection.collapse(animated: false)
        
        VStack(spacing: 16, viewModel.contactDetailViews)
            .embed(in: contactDetailsSection.contentView.readableWidth)
        
        // Inform
        let informContactSection = SectionView(title: .informContactSectionTitle, caption: .informContactSectionMessageIndex, index: 3)
        informContactSection.collapse(animated: false)
        
        let informTitleLabel = Label(bodyBold: "").multiline()
        let informTextView = TextView()
        let informButton = Button(title: .informContactShareGuidelines, style: .primary).touchUpInside(self, action: #selector(informContact))
        
        viewModel.informTitleHandler = { informTitleLabel.text = $0 }
        viewModel.informContentHandler = { informTextView.html($0, textColor: Theme.colors.captionGray) }
        viewModel.informButtonTypeHandler = { informButton.style = $0 }
        
        VStack(spacing: 0,
               VStack(spacing: 16,
                      informTitleLabel,
                      informTextView),
               informButton)
            .embed(in: informContactSection.contentView.readableWidth)
        
        viewModel.classificationSectionView = classificationSectionView
        viewModel.detailsSectionView = contactDetailsSection
        viewModel.informSectionView = informContactSection

        scrollView = SectionedScrollView(classificationSectionView,
                                         contactDetailsSection,
                                         informContactSection)
        scrollView.embed(in: contentView)
        scrollView.keyboardDismissMode = .onDrag
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        
        registerForKeyboardNotifications()
    }
    
    private var contactDetailsSection: SectionView!
    
    @objc private func save() {
        let task = viewModel.updatedTask
        let firstName = task.contactFirstName ?? ""
        
        switch task.contact.communication {
        case .index where task.contact.didInform,
             .staff where task.isOrCanBeInformed,
             .none:
            delegate?.contactQuestionnaireViewController(self, didSave: viewModel.updatedTask)
        case .index:
            let alert = UIAlertController(title: .contactInformPromptTitle(firstName: firstName), message: nil, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactInformOptionDone, style: .default) { _ in
                self.viewModel.registerDidInform()
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactInformActionInformLater, style: .default) { _ in
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactInformActionInformNow, style: .default) { _ in
                // Scroll to the inform section
                let informSection = self.viewModel.informSectionView!
                
                self.viewModel.classificationSectionView?.collapse(animated: true)
                self.viewModel.detailsSectionView?.collapse(animated: true)
                informSection.expand(animated: true)
                
                self.scrollView.scrollRectToVisible(informSection.frame, animated: true)
            })
            
            present(alert, animated: true)
        case .staff:
            let alert = UIAlertController(title: .contactMissingDetailsPromptTitle(firstName: firstName), message: .contactMissingDetailsPromptMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactMissingDetailsActionIgnore, style: .default) { _ in
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactMissingDetailsActionFillIn, style: .default) { _ in
                // Scroll to contact details section
                let detailsSection = self.viewModel.detailsSectionView!
                
                self.viewModel.classificationSectionView?.collapse(animated: true)
                self.viewModel.informSectionView?.collapse(animated: true)
                detailsSection.expand(animated: true)
                
                // Only interested in the top part
                var adjustedFrame = detailsSection.frame
                adjustedFrame.size.height /= 2
                
                self.scrollView.scrollRectToVisible(adjustedFrame, animated: true)
            })
            
            present(alert, animated: true)
        }
    }
    
    @objc private func cancel() {
        delegate?.contactQuestionnaireViewControllerDidCancel(self)
    }
    
    @objc private func informContact() {
        delegate?.contactQuestionnaireViewController(self, wantsToInformContact: viewModel.updatedTask) { [weak self] success in
            if success {
                self?.viewModel.registerDidInform()
            }
        }
    }
    
    // MARK: - Keyboard handling
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        
        let convertedFrame = view.window?.convert(endFrame, to: contentView)
        
        let inset = contentView.frame.maxY - (convertedFrame?.minY ?? 0)
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}
