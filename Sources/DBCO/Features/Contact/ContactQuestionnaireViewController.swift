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
    
    var updatedTask: Task {
        let updatedCategory = updatedClassification.category ?? task.contact.category
        
        var updatedTask = task
        updatedTask.contact = Task.Contact(category: updatedCategory,
                                           communication: task.contact.communication)
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
    
    init(task: Task?, contact: CNContact? = nil, showCancelButton: Bool = false) {
        let initialCategory = task?.contact.category
        let task = task ?? Task.emptyContactTask
        self.task = task
        self.title = task.contactName ?? .contactFallbackTitle
        self.showCancelButton = showCancelButton
        
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
                
                updateProgress()
            }
        }
        
        self.title = updatedTask.contactName ?? .contactFallbackTitle
    }
    
    private func updateClassification(with result: ClassificationHelper.Result) {
        updatedClassification = result
        
        var taskCategory = task.contact.category
        
        if case .success(let updatedCategory) = result {
            taskCategory = updatedCategory
        }
        
        answerManagers.forEach {
            $0.view.isHidden = !$0.question.isRelevant(in: taskCategory)
        }
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
        informSectionView?.isCompleted = otherManagers.allSatisfy(\.hasValidAnswer)
        
        if expandFirstUnfinishedSection {
            let sections = [classificationSectionView, detailsSectionView, informSectionView].compactMap { $0 }
            sections.forEach { $0.collapse(animated: false) }
            sections.first { !$0.isCompleted }?.expand(animated: false)
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
        
        func groupHeaderLabel(title: String) -> UILabel {
            let label = UILabel()
            label.font = Theme.fonts.bodyBold
            label.numberOfLines = 0
            label.text = title
            
            return label
        }
        
        func listItem(text: String.SubSequence) -> UIView {
            let label = UILabel()
            label.font = Theme.fonts.body
            label.textColor = Theme.colors.captionGray
            label.numberOfLines = 0
            label.text = String(text)
            
            let icon = UIImageView(image: UIImage(named: "ListItem"))
            icon.setContentHuggingPriority(.required, for: .horizontal)
            
            return HStack(spacing: 12, icon.withInsets(.topBottom(7)), label)
                .alignment(.top)
        }
        
        func list(from multilineText: String) -> UIView {
            return VStack(spacing: 8, multilineText.split(separator: "\n").map(listItem))
        }
        
        
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
        let informContactSection = SectionView(title: .informContactSectionTitle, caption: .informContactSectionMessage, index: 3)
        informContactSection.collapse(animated: false)
        
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
