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
    
    var updatedTask: Task {
        let updatedCategory = updatedClassification.category ?? task.contact.category
        
        var updatedTask = task
        updatedTask.contact = Task.Contact(category: updatedCategory,
                                           communication: updatedContact.communication,
                                           informedByIndexAt: updatedContact.informedByIndexAt,
                                           dateOfLastExposure: updatedContact.dateOfLastExposure)
        updatedTask.questionnaireResult = baseResult
        updatedTask.questionnaireResult?.answers = answerManagers.map(\.answer)
        
        return updatedTask
    }
    
    private(set) var title: String
    let showCancelButton: Bool
    
    private(set) var answerManagers: [AnswerManaging]
    
    // swiftlint:disable opening_brace
    weak var classificationSectionView: SectionView?    { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var detailsSectionView: SectionView?           { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    weak var informSectionView: SectionView?            { didSet { updateProgress(expandFirstUnfinishedSection: true) } }
    // swiftlint:enable opening_brace
    
    @Bindable private(set) var informTitle: String
    @Bindable private(set) var informIntro: String
    @Bindable private(set) var informContent: String
    @Bindable private(set) var informLink: String
    @Bindable private(set) var informFooter: String
    @Bindable private(set) var informFooterHidden: Bool
    @Bindable private(set) var informButtonTitle: String
    @Bindable private(set) var informButtonHidden: Bool
    @Bindable private(set) var copyButtonHidden: Bool
    @Bindable private(set) var informButtonType: Button.ButtonType
    @Bindable private(set) var promptButtonType: Button.ButtonType
    @Bindable private(set) var promptButtonTitle: String
    
    init(task: Task?, questionnaire: Questionnaire, contact: CNContact? = nil, showCancelButton: Bool = false) {
        self.didCreateNewTask = task == nil
        
        let initialCategory = task?.contact.category
        let task = task ?? Task.emptyContactTask
        self.task = task
        self.updatedContact = task.contact
        self.title = task.contactName ?? .contactFallbackTitle
        self.showCancelButton = showCancelButton
        
        self.informTitle = ""
        self.informIntro = ""
        self.informContent = ""
        self.informLink = ""
        self.informFooter = ""
        self.informFooterHidden = true
        self.copyButtonHidden = true
        self.informButtonTitle = ""
        self.informButtonHidden = true
        self.informButtonType = .secondary
        self.promptButtonType = .primary
        self.promptButtonTitle = .save
        
        let questionsAndAnswers: [(question: Question, answer: Answer)] = {
            let currentAnswers = task.questionnaireResult?.answers ?? []
            
            return questionnaire.questions.map { question in
                (question, currentAnswers.first { $0.questionUuid == question.uuid } ?? question.emptyAnswer)
            }
        }()
        
        self.baseResult = QuestionnaireResult(questionnaireUuid: questionnaire.uuid, answers: questionsAndAnswers.map(\.answer))
        
        self.answerManagers = []
        self.updatedClassification = .success(task.contact.category)
        
        self.answerManagers = questionsAndAnswers.compactMap { question, answer in
            let manager: AnswerManaging
            
            switch answer.value {
            case .classificationDetails:
                manager = ClassificationDetailsAnswerManager(question: question, answer: answer, contactCategory: initialCategory)
            case .contactDetails:
                manager = ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .contactDetailsFull:
                manager = ContactDetailsAnswerManager(question: question, answer: answer, contact: contact)
            case .date:
                manager = DateAnswerManager(question: question, answer: answer)
            case .open:
                manager = OpenAnswerManager(question: question, answer: answer)
            case .multipleChoice:
                manager = MultipleChoiceAnswerManager(question: question, answer: answer, contact: task.contact)
            case .lastExposureDate:
                manager = LastExposureDateAnswerManager(question: question, answer: answer, lastExposureDate: updatedContact.dateOfLastExposure)
            }
            
            manager.isEnabled = !question.disabledForSources.contains(task.source)
            
            return manager
        }
        
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
        // Tasks that had their "communication" set to .staff in the portal cannot be set to .index in the app
        let portalTask = Services.caseManager.portalTasks.first { $0.uuid == task.uuid } ?? task
        let isFixedToStaff = portalTask.source == .portal && portalTask.contact.communication == .staff
       
        guard !isFixedToStaff else { return updateInformSectionContent() }
        
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: .index,
                                      informedByIndexAt: updatedContact.informedByIndexAt,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
        updateInformSectionContent()
    }
    
    private func setCommunicationToStaff() {
        updatedContact = Task.Contact(category: updatedContact.category,
                                      communication: .staff,
                                      informedByIndexAt: updatedContact.informedByIndexAt,
                                      dateOfLastExposure: updatedContact.dateOfLastExposure)
        updateInformSectionContent()
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
        
        let hasCommunicationTypeQuestion = contactDetailsManagers.contains { $0.question.answerOptions?.contains { $0.trigger == .setCommunicationToIndex } == true }
        let hasValidCommunication = updatedContact.communication != .none || !hasCommunicationTypeQuestion // true is there is a valid answer or, there is no question for a valid answer
        
        func isCompleted(_ answer: Answer) -> Bool {
            return answer.progressElements.allSatisfy { $0 }
        }
        
        let classificationCompleted = classificationManagers
            .map(\.answer)
            .filter(\.isEssential)
            .allSatisfy(isCompleted)
        
        let detailsCompleted = hasValidCommunication && contactDetailsManagers
            .map(\.answer)
            .filter(\.isEssential)
            .allSatisfy(isCompleted)
        
        let allDetailsFilledIn = contactDetailsManagers
            .map(\.answer)
            .allSatisfy(isCompleted)
        
        let classificationIsHidden = classificationManagers.allSatisfy { !$0.isEnabled }
        classificationSectionView?.isCompleted = classificationCompleted
        classificationSectionView?.isHidden = classificationIsHidden
        classificationSectionView?.index = 1
        detailsSectionView?.isCompleted = detailsCompleted
        informSectionView?.isCompleted = updatedTask.isOrCanBeInformed
        
        let detailsSectionWasDisabled = detailsSectionView?.isEnabled == false
        detailsSectionView?.isEnabled = classificationManagers.allSatisfy(\.hasValidAnswer)
        detailsSectionView?.index = classificationIsHidden ? 1 : 2
        
        let informSectionWasDisabled = informSectionView?.isEnabled == false
        informSectionView?.index = classificationIsHidden ? 2 : 3
        informSectionView?.isEnabled =
            hasValidCommunication &&
            classificationManagers.allSatisfy(\.hasValidAnswer) &&
            !updatedContact.shouldBeDeleted
        
        if expandFirstUnfinishedSection {
            let sections = [classificationSectionView, detailsSectionView, informSectionView].compactMap { $0 }
            sections.forEach { $0.collapse(animated: false) }
            
            if !classificationCompleted {
                classificationSectionView?.expand(animated: false)
            } else if !allDetailsFilledIn {
                detailsSectionView?.expand(animated: false)
                if informSectionView?.isEnabled == true { // Since the inform section is not disabled, it will not auto expand when the communication question is answered
                    informSectionView?.expand(animated: false)
                }
            } else if sections.allSatisfy(\.isCollapsed) {
                informSectionView?.expand(animated: false)
            }
        } else if detailsSectionWasDisabled && (detailsSectionView?.isEnabled == true) { // Expand details section if it became enabled
            detailsSectionView?.expand(animated: true)
            
            // If there is already a valid communication or there's no communication question, expand the inform section too
            if hasValidCommunication {
                informSectionView?.expand(animated: true)
            }
            
        } else if informSectionWasDisabled && (informSectionView?.isEnabled == true) { // Expand inform section if it became enabled
            informSectionView?.expand(animated: true)
        }
        
        updateInformSectionContent()
    }
    
    private func updateInformSectionContent() {
        let firstName = updatedTask.contactFirstName
        
        func setInformButtonTitle() {
            if updatedTask.contactPhoneNumber != nil && Services.configManager.featureFlags.enableContactCalling {
                informButtonTitle = .informContactCall(firstName: firstName)
                informButtonHidden = false
            } else {
                informButtonHidden = true
            }
        }
        
        copyButtonHidden = !Services.configManager.featureFlags.enablePerspectiveCopy
        
        switch updatedContact.communication {
        case .index, .none:
            informTitle = .informContactTitleIndex(firstName: firstName)
            informFooter = .informContactFooterIndex(firstName: firstName)
            informButtonType = .primary
            promptButtonType = .secondary
            setInformButtonTitle()
        case .staff:
            informTitle = .informContactTitleStaff(firstName: firstName)
            informFooter = .informContactFooterStaff(firstName: firstName)
            informButtonType = .secondary
            promptButtonType = .primary
            setInformButtonTitle()
        }
        
        informFooterHidden = didCreateNewTask
        
        promptButtonTitle = .save
        
        if let dateValue = updatedContact.dateOfLastExposure,
           let exposureDate = LastExposureDateAnswerManager.valueDateFormatter.date(from: dateValue),
           let exposureDatePlus5 = Calendar.current.date(byAdding: .day, value: 5, to: exposureDate),
           let exposureDatePlus10 = Calendar.current.date(byAdding: .day, value: 10, to: exposureDate),
           let exposureDatePlus11 = Calendar.current.date(byAdding: .day, value: 11, to: exposureDate),
           let exposureDatePlus14 = Calendar.current.date(byAdding: .day, value: 14, to: exposureDate) {
            
            let formatter = DateFormatter()
            formatter.dateFormat = .informContactGuidelinesDateFormat
            formatter.calendar = Calendar.current
            formatter.locale = Locale.current
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            informContent = .informContactGuidelines(category: updatedContact.category,
                                                     exposureDatePlus5: formatter.string(from: exposureDatePlus5),
                                                     exposureDatePlus10: formatter.string(from: exposureDatePlus10),
                                                     exposureDatePlus11: formatter.string(from: exposureDatePlus11),
                                                     exposureDatePlus14: formatter.string(from: exposureDatePlus14))
            informIntro = .informContactGuidelinesIntro(category: updatedContact.category,
                                                        exposureDate: formatter.string(from: exposureDate))
        } else {
            informContent = .informContactGuidelinesGeneric(category: updatedContact.category)
            informIntro = .informContactGuidelinesIntroGeneric(category: updatedContact.category)
        }
        
        if updatedContact.shouldBeDeleted {
            promptButtonType = .secondary
            promptButtonTitle = didCreateNewTask ? .cancel : .delete
        }
        
        informLink = .informContactLink(category: updatedTask.contact.category)
    }
    
    private func view(manager: AnswerManaging) -> UIView {
        let view = manager.view
        let isRelevant = manager.question.isRelevant(in: task.contact.category)
        view.isHidden = !isRelevant || !manager.isEnabled
        
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
    
    func setInputFieldDelegate(_ delegate: InputFieldDelegate) {
        answerManagers.forEach { $0.inputFieldDelegate = delegate }
    }
}

protocol ContactQuestionnaireViewControllerDelegate: class {
    func contactQuestionnaireViewControllerDidCancel(_ controller: ContactQuestionnaireViewController)
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, didSave contactTask: Task)
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, wantsToOpen url: URL)
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
        let promptButton = Button(title: .save)
            .touchUpInside(self, action: #selector(save))
        
        promptView = promptButton
        
        viewModel.setInputFieldDelegate(self)
        
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
        informContactSection.showBottomSeparator = false
        informContactSection.collapse(animated: false)
        
        let informTitleLabel = Label(bodyBold: "").multiline()
        let informTextView = TextView().linkTouched { [unowned self] in
            delegate?.contactQuestionnaireViewController(self, wantsToOpen: $0)
        }
        let informLinkView = TextView().linkTouched { [unowned self] in
            delegate?.contactQuestionnaireViewController(self, wantsToOpen: $0)
        }
        let informFooterLabel = Label(bodyBold: "").multiline()
        
        let informButton = Button(title: "", style: .primary)
            .touchUpInside(self, action: #selector(informContact))
        
        let copyButton = Button(title: .informContactCopyGuidelines, style: .secondary)
            .touchUpInside(self, action: #selector(copyGuidelines))
        
        viewModel.$informTitle.binding = { informTitleLabel.attributedText = .makeFromHtml(text: $0, font: Theme.fonts.bodyBold, textColor: .black) }
        viewModel.$informContent.binding = { informTextView.html($0, textColor: Theme.colors.captionGray) }
        viewModel.$informLink.binding = { informLinkView.html($0, textColor: Theme.colors.captionGray) }
        viewModel.$informFooter.binding = { informFooterLabel.attributedText = .makeFromHtml(text: $0, font: Theme.fonts.bodyBold, textColor: .black) }
        viewModel.$informFooterHidden.binding = { informFooterLabel.isHidden = $0 }
        viewModel.$copyButtonHidden.binding = { copyButton.isHidden = $0 }
        viewModel.$informButtonTitle.binding = { informButton.title = $0 }
        viewModel.$informButtonHidden.binding = { informButton.isHidden = $0 }
        viewModel.$informButtonType.binding = { informButton.style = $0 }
        viewModel.$promptButtonType.binding = { promptButton.style = $0 }
        viewModel.$promptButtonTitle.binding = { promptButton.title = $0 }

        VStack(spacing: 24,
               VStack(spacing: 16,
                      informTitleLabel,
                      informTextView,
                      informLinkView,
                      informFooterLabel),
               VStack(spacing: 16,
                      copyButton,
                      informButton))
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
        var task = viewModel.updatedTask
        let firstName = task.contactFirstName ?? .contactPromptNameFallback
        
        guard !task.contact.shouldBeDeleted else { // if task is not valid and should be deleted
            if viewModel.didCreateNewTask {
                delegate?.contactQuestionnaireViewControllerDidCancel(self)
            } else {
                let alert = UIAlertController(title: .contactDeletePromptTitle, message: nil, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: .no, style: .default))
                
                alert.addAction(UIAlertAction(title: .yes, style: .default) { _ in
                    // mark task as deleted
                    task.deletedByIndex = true
                    self.delegate?.contactQuestionnaireViewController(self, didSave: task)
                })
                
                present(alert, animated: true)
            }
            
            return
        }
        
        switch task.contact.communication {
        case .index where task.contact.informedByIndexAt != nil,
             .staff where task.isOrCanBeInformed:
            delegate?.contactQuestionnaireViewController(self, didSave: viewModel.updatedTask)
        case .index, .none:
            let alert = UIAlertController(title: .contactInformPromptTitle(firstName: firstName), message: .contactInformPromptMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactInformOptionDone, style: .default) { _ in
                self.viewModel.registerDidInform()
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactInformActionInformLater, style: .default) { _ in
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactInformActionInformNow, style: .default) { _ in
                self.scrollToInformSection()
            })
            
            present(alert, animated: true)
        case .staff:
            let alert = UIAlertController(title: .contactMissingDetailsPromptTitle(firstName: firstName), message: .contactMissingDetailsPromptMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactMissingDetailsActionIgnore, style: .default) { _ in
                self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
            })
            
            alert.addAction(UIAlertAction(title: .contactMissingDetailsActionFillIn, style: .default) { _ in
                self.scrollToDetailsSection()
            })
            
            present(alert, animated: true)
        }
    }
    
    private func scrollToDetailsSection() {
        // Scroll to contact details section
        let detailsSection = viewModel.detailsSectionView!
        
        viewModel.classificationSectionView?.collapse(animated: true)
        viewModel.informSectionView?.collapse(animated: true)
        detailsSection.expand(animated: true)
        
        // Only interested in the top part
        var adjustedFrame = detailsSection.frame
        adjustedFrame.size.height /= 2
        
        scrollView.scrollRectToVisible(adjustedFrame, animated: true)
    }
    
    private func scrollToInformSection() {
        // Scroll to the inform section
        let informSection = viewModel.informSectionView!
        
        viewModel.classificationSectionView?.collapse(animated: true)
        viewModel.detailsSectionView?.collapse(animated: true)
        informSection.expand(animated: true)
        
        scrollView.scrollRectToVisible(informSection.frame, animated: true)
    }
    
    @objc private func cancel() {
        delegate?.contactQuestionnaireViewControllerDidCancel(self)
    }
    
    @objc private func informContact() {
        if let phoneNumber = viewModel.updatedTask.contactPhoneNumber?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            if let url = URL(string: "tel:\(phoneNumber)") {
                delegate?.contactQuestionnaireViewController(self, wantsToOpen: url)
            }
        } else {
            scrollToDetailsSection()
        }
    }
    
    @objc private func copyGuidelines(_ sender: Button) {
        UIPasteboard.general.string = viewModel.copyableGuidelines
        
        sender.flashTitle(.informContactCopyGuidelinesAction)
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

extension ContactQuestionnaireViewController: InputFieldDelegate {
    
    func promptOptionsForInputField(_ options: [String], selectOption: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        options.forEach { option in
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                selectOption(option)
            })
        }
        
        alert.addAction(UIAlertAction(title: .other, style: .default) { _ in
            selectOption(nil)
        })
        
        alert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
}
