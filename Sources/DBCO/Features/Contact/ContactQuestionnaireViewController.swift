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
                                           didInform: updatedContact.didInform)
        updatedTask.result = baseResult
        updatedTask.result?.answers = answerManagers.map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    let showCancelButton: Bool
    
    private var answerManagers: [AnswerManaging]
    
    weak var classificationSectionView: SectionView?    { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var detailsSectionView: SectionView?           { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var informSectionView: SectionView?            { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    
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
        
        let questionnaire = Services.taskManager.questionnaire(for: task)
        
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
                return MultipleChoiceAnswerManager(question: question, answer: answer)
            }
        }
        
        answerManagers.forEach {
            $0.updateHandler = { [unowned self] in
                switch $0 {
                case let classificationManager as ClassificationDetailsAnswerManager:
                    updateClassification(with: classificationManager.classification)
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
                                      didInform: updatedContact.didInform)
        updateInformSectionContent()
    }
    
    private func setCommunicationToStaff() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: .staff,
                                      didInform: updatedContact.didInform)
        updateInformSectionContent()
    }
    
    func registerDidInform() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: updatedContact.communication,
                                      didInform: true)
    }
    
    private func updateClassification(with result: ClassificationHelper.Result) {
        updatedClassification = result
        
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = result {
            taskCategory = updatedCategory
            updatedContact = Task.Contact(category: taskCategory,
                                          communication: updatedContact.communication,
                                          didInform: updatedContact.didInform)
        }
        
        answerManagers.forEach {
            $0.view.isHidden = !$0.question.isRelevant(in: taskCategory)
        }
        
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
            informContent = .informContactGuidelinesClose
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

final class ContactQuestionnaireViewController: PromptableViewController {
    private let viewModel: ContactQuestionnaireViewModel
    private let scrollView = UIScrollView()
    
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
        
        scrollView.embed(in: contentView)
        scrollView.keyboardDismissMode = .interactive
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        
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
        
        VStack(classificationSectionView,
               contactDetailsSection,
               informContactSection)
            .embed(in: scrollView)
        
        registerForKeyboardNotifications()
    }
    
    private var contactDetailsSection: SectionView!
    
    @objc private func save() {
        delegate?.contactQuestionnaireViewController(self, didSave: viewModel.updatedTask)
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
