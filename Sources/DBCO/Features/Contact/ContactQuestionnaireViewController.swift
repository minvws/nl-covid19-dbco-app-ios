/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

class ContactQuestionnaireViewModel {
    private var task: Task
    private var baseResult: QuestionnaireResult
    
    var updatedTask: Task {
        var updatedTask = task
        updatedTask.result = baseResult
        updatedTask.result?.answers = answerManagers.map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    let showCancelButton: Bool
    
    private let answerManagers: [AnswerManaging]
    
    init(task: Task, contact: CNContact? = nil, showCancelButton: Bool = false) {
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
        
        self.answerManagers = questionsAndAnswers.compactMap { question, answer in
            switch answer.value {
            case .classificationDetails:
                return ClassificationDetailsAnswerManager(question: question, answer: answer, contactCategory: task.contact.category)
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
        
        self.title = updatedTask.contactName ?? .contactFallbackTitle
    }
    
    private func view(manager: AnswerManaging) -> UIView {
        let view = manager.view
        let isRelevant = manager.question.relevantForCategories.contains(task.contact.category)
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
        let contactTypeSection = SectionView(title: .contactTypeSectionTitle, caption: .contactTypeSectionMessage, index: 1)
        contactTypeSection.isCompleted = true
        contactTypeSection.collapse(animated: false)
        
        VStack(spacing: 24, viewModel.classificationViews)
            .embed(in: contactTypeSection.contentView.readableWidth)
        
        // Details
        let contactDetailsSection = SectionView(title: .contactDetailsSectionTitle, caption: .contactDetailsSectionMessage, index: 2)
        
        VStack(spacing: 16, viewModel.contactDetailViews)
            .embed(in: contactDetailsSection.contentView.readableWidth)
        
        // Inform
        let informContactSection = SectionView(title: .informContactSectionTitle, caption: .informContactSectionMessage, index: 3)
        informContactSection.collapse(animated: false)
        
        VStack(contactTypeSection,
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
