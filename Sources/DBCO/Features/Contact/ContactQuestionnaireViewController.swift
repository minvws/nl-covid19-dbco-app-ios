/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        if viewModel.showDeleteButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "DeleteContact"), style: .plain, target: self, action: #selector(deleteTask))
        }
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        setupViews()
        
        registerForKeyboardNotifications()
    }
    
    private func setupViews() {
        let promptButton = Button(title: .save)
            .touchUpInside(self, action: #selector(save))
        
        promptView = promptButton
        
        viewModel.setInputFieldDelegate(self)
        
        let classificationSectionView = createClassificationSectionView()
        let contactDetailsSection = createDetailsSectionView()
        let informContactSection = createInformSectionView()
        
        viewModel.$promptButtonType.binding = { promptButton.style = $0 }
        viewModel.$promptButtonTitle.binding = { promptButton.title = $0 }
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewModel.isDisabled {
            let alert = UIAlertController(title: .contactReadonlyPromptTitle, message: .contactReadonlyPromptMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactReadonlyPromptButton, style: .default))
            
            present(alert, animated: true)
        }
    }
    
    private func createClassificationSectionView() -> SectionView {
        let sectionView = SectionView(title: .contactTypeSectionTitle, caption: .contactTypeSectionMessage, index: 1)
        sectionView.expand(animated: false)
        
        VStack(spacing: 24, viewModel.classificationViews)
            .embed(in: sectionView.contentView.readableWidth)
        
        return sectionView
    }
    
    private func createDetailsSectionView() -> SectionView {
        let sectionView = SectionView(title: .contactDetailsSectionTitle, caption: .contactDetailsSectionMessage, index: 2)
        sectionView.collapse(animated: false)
        
        VStack(spacing: 16, viewModel.contactDetailViews)
            .embed(in: sectionView.contentView.readableWidth)
        
        return sectionView
    }
    
    private func createInformSectionView() -> SectionView {
        let sectionView = SectionView(title: .informContactSectionTitle, caption: .informContactSectionMessage, index: 3)
        sectionView.showBottomSeparator = false
        sectionView.collapse(animated: false)
        
        let informTitleLabel = UILabel(bodyBold: "").multiline()
        let informTextView = TextView().linkTouched { [unowned self] in
            delegate?.contactQuestionnaireViewController(self, wantsToOpen: $0)
        }
        let informLinkView = TextView().linkTouched { [unowned self] in
            delegate?.contactQuestionnaireViewController(self, wantsToOpen: $0)
        }
        let informFooterLabel = UILabel(bodyBold: "").multiline()
        
        let informButton = Button(title: "", style: .primary)
            .touchUpInside(self, action: #selector(informContact))
        
        let copyButton = Button(title: .informContactCopyGuidelines, style: .secondary)
            .touchUpInside(self, action: #selector(copyGuidelines))
        
        VStack(spacing: 24,
               VStack(spacing: 16,
                      informTitleLabel,
                      informTextView,
                      informLinkView,
                      informFooterLabel),
               VStack(spacing: 16,
                      copyButton,
                      informButton))
            .embed(in: sectionView.contentView.readableWidth)
        
        viewModel.$informTitle.binding = { informTitleLabel.attributedText = .makeFromHtml(text: $0, font: Theme.fonts.bodyBold, textColor: .black) }
        viewModel.$informContent.binding = { informTextView.html($0, textColor: Theme.colors.captionGray) }
        viewModel.$informLink.binding = { informLinkView.html($0, textColor: Theme.colors.captionGray) }
        viewModel.$informFooter.binding = { informFooterLabel.attributedText = .makeFromHtml(text: $0, font: Theme.fonts.bodyBold, textColor: .black) }
        viewModel.$copyButtonHidden.binding = { copyButton.isHidden = $0 }
        viewModel.$copyButtonType.binding = { copyButton.style = $0 }
        viewModel.$informButtonTitle.binding = { informButton.title = $0 }
        viewModel.$informButtonHidden.binding = { informButton.isHidden = $0 }
        viewModel.$informButtonType.binding = { informButton.style = $0 }
        
        return sectionView
    }
    
    private var contactDetailsSection: SectionView!
    
    private func deleteInvalidTask() {
        var task = viewModel.updatedTask
        
        if viewModel.didCreateNewTask {
            delegate?.contactQuestionnaireViewControllerDidCancel(self)
        } else {
            let alert = UIAlertController(title: .contactDeletePromptTitle, message: .contactDeletePromptMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .back, style: .default))
            
            alert.addAction(UIAlertAction(title: .delete, style: .default) { _ in
                // mark task as deleted
                task.deletedByIndex = true
                self.delegate?.contactQuestionnaireViewController(self, didSave: task)
            })
            
            present(alert, animated: true)
        }
    }
    
    private func promptInformAndSave() {
        let firstName = viewModel.updatedTask.contactFirstName ?? .contactPromptNameFallback
        
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
    }
    
    private func promptMissingDetailsAndSave() {
        let firstName = viewModel.updatedTask.contactFirstName ?? .contactPromptNameFallback
        
        let alert = UIAlertController(title: .contactMissingDetailsPromptTitle(firstName: firstName), message: .contactMissingDetailsPromptMessage, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .contactMissingDetailsActionIgnore, style: .default) { _ in
            self.delegate?.contactQuestionnaireViewController(self, didSave: self.viewModel.updatedTask)
        })
        
        alert.addAction(UIAlertAction(title: .contactMissingDetailsActionFillIn, style: .default) { _ in
            self.scrollToDetailsSection()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func save() {
        guard !viewModel.isDisabled else {
            delegate?.contactQuestionnaireViewControllerDidCancel(self)
            return
        }
        
        guard !viewModel.contactShouldBeDeleted else { // if task is not valid and should be deleted
            return deleteInvalidTask()
        }
        
        let task = viewModel.updatedTask
        
        switch task.contact.communication {
        case _ where task.contact.informedByIndexAt != nil, .staff where task.isOrCanBeInformed:
            delegate?.contactQuestionnaireViewController(self, didSave: viewModel.updatedTask)
        case .index, .unknown:
            promptInformAndSave()
        case .staff:
            promptMissingDetailsAndSave()
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
        func cancel() {
            if navigationController?.viewControllers.count ?? 0 > 1 {
                navigationController?.popViewController(animated: true)
            } else {
                delegate?.contactQuestionnaireViewControllerDidCancel(self)
            }
        }
        
        guard !viewModel.canSafelyCancel else { return cancel() }
        
        let alert = UIAlertController(title: .informContactCancelPromptTitle, message: .informContactCancelPromptMessage, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .yes, style: .default) { _ in
            cancel()
        })
        
        alert.addAction(UIAlertAction(title: .no, style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func deleteTask() {
        let alert = UIAlertController(title: .informContactDeletePromptTitle, message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .back, style: .default))
        
        alert.addAction(UIAlertAction(title: .delete, style: .default) { _ in
            // mark task as deleted
            var task = self.viewModel.updatedTask
            task.deletedByIndex = true
            self.delegate?.contactQuestionnaireViewController(self, didSave: task)
        })
        
        present(alert, animated: true)
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
    
    func shouldShowValidationResult(_ result: ValidationResult, for sender: AnyObject) -> Bool {
        guard viewModel.isDisabled == false else { return false }
        switch result {
        case .empty:
            return !viewModel.didCreateNewTask
        default:
            return true
        }
    }
    
}
