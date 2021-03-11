/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts
import ContactsUI

protocol SelectContactCoordinatorDelegate: class {
    func selectContactCoordinator(_ coordinator: SelectContactCoordinator, didFinishWith task: Task)
    func selectContactCoordinatorDidCancel(_ coordinator: SelectContactCoordinator)
}

/// Coordinator managing the flow of querying for access to the phone's contacts, selecting a contact from the phone's contacts and prefilling the questionnaire for an existing or new task.
/// Uses [ContactQuestionnaireViewController](x-source-tag://ContactQuestionnaireViewController)
/// and [SelectContactViewController](x-source-tag://SelectContactViewController).
/// - Tag: SelectContactCoordinator
final class SelectContactCoordinator: Coordinator, Logging {
    
    let loggingCategory = "SelectContactCoordinator"
    
    private weak var delegate: SelectContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private let task: Task?
    private var updatedTask: Task?
    private var questionnaire: Questionnaire!
    
    @UserDefaults(key: "SelectContactCoordinator.didSelectManualEntry")
    private(set) var didSelectManualEntry: Bool = false // swiftlint:disable:this let_var_whitespace
    
    init(presenter: UIViewController, contactTask: Task?, delegate: SelectContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.task = contactTask
    }
    
    override func start() {
        guard let questionnaire = try? Services.caseManager.questionnaire(for: .contact) else {
            logError("Could not get questionnaire for contact task")
            delegate?.selectContactCoordinatorDidCancel(self)
            return
        }
        
        self.questionnaire = questionnaire
        
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch currentStatus {
        case .authorized:
            if let contactIdentifier = task?.contact.contactIdentifier {
                let editViewModel = ContactQuestionnaireViewModel(task: task,
                                                                  questionnaire: questionnaire,
                                                                  contact: findContact(with: contactIdentifier),
                                                                  showCancelButton: true)
                let editController = ContactQuestionnaireViewController(viewModel: editViewModel)
                editController.delegate = self
                
                presentNavigationController(with: editController)
            } else {
                let viewModel = SelectContactViewModel(suggestedName: task?.label)
                let selectController = SelectContactViewController(viewModel: viewModel)
                selectController.delegate = self
                
                presentNavigationController(with: selectController)
            }
            
        case .notDetermined where didSelectManualEntry == false:
            requestContactsAuthorization()
            
        default:
            continueWithoutAuthorization()
        }
    }
    
    private func callDelegate() {
        if let updatedTask = updatedTask {
            delegate?.selectContactCoordinator(self, didFinishWith: updatedTask)
        } else {
            delegate?.selectContactCoordinatorDidCancel(self)
        }
    }
    
    private func presentNavigationController(with controller: UIViewController) {
        navigationController.setViewControllers([controller], animated: false)
        presenter?.present(navigationController, animated: true)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.callDelegate()
        }
    }
    
    private func continueAfterAuthorization() {
        let viewModel = SelectContactViewModel(suggestedName: task?.label)
        let selectController = SelectContactViewController(viewModel: viewModel)
        selectController.delegate = self
        
        presentNavigationController(with: selectController)
    }
    
    private func requestContactsAuthorization() {
        let viewModel = ContactsAuthorizationViewModel(contactName: task?.contactFirstName, style: .selectContact)
        let controller = ContactsAuthorizationViewController(viewModel: viewModel)
        controller.delegate = self
        controller.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.callDelegate()
        }
        
        presenter?.present(controller, animated: true)
    }
    
    private func continueWithoutAuthorization() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(
            UIAlertAction(title: .selectContactFromContactsFallback, style: .default) { _ in
                self.continueWithSystemContactPicker()
            })
        
        actionSheet.addAction(
            UIAlertAction(title: .selectContactAddManuallyFallback, style: .default) { _ in
                self.continueManually()
            })
        
        actionSheet.addAction(
            UIAlertAction(title: .cancel, style: .cancel) { _ in
                self.callDelegate()
            })
        
        presenter?.present(actionSheet, animated: true)
    }
    
    private func continueWithSystemContactPicker() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        
        presenter?.present(picker, animated: true)
    }
    
    private func continueManually() {
        let editViewModel = ContactQuestionnaireViewModel(task: task, questionnaire: questionnaire, showCancelButton: true)
        let editController = ContactQuestionnaireViewController(viewModel: editViewModel)
        editController.delegate = self
        
        presentNavigationController(with: editController)
    }
    
    private func findContact(with identifier: String) -> CNContact? {
        guard case .authorized = CNContactStore.authorizationStatus(for: .contacts) else { return nil }
        
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor
        ]
        
        return try? CNContactStore().unifiedContact(withIdentifier: identifier, keysToFetch: keys)
    }
}

extension SelectContactCoordinator: ContactsAuthorizationViewControllerDelegate {
    
    func contactsAuthorizationViewControllerDidSelectAllow(_ controller: ContactsAuthorizationViewController) {
        CNContactStore().requestAccess(for: .contacts) { authorized, error in
            DispatchQueue.main.async {
                controller.onDismissed = nil
                controller.dismiss(animated: true) {
                    if authorized {
                        self.continueAfterAuthorization()
                    } else {
                        self.continueWithoutAuthorization()
                    }
                }
            }
        }
    }
    
    func contactsAuthorizationViewControllerDidSelectManual(_ controller: ContactsAuthorizationViewController) {
        controller.onDismissed = nil
        didSelectManualEntry = true
        controller.dismiss(animated: true) {
            self.continueWithoutAuthorization()
        }
    }
}

extension SelectContactCoordinator: SelectContactViewControllerDelegate {
    
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact) {
        let viewModel = ContactQuestionnaireViewModel(task: task, questionnaire: questionnaire, contact: contact)
        let detailsController = ContactQuestionnaireViewController(viewModel: viewModel)
        detailsController.delegate = self
        
        navigationController.pushViewController(detailsController, animated: true)
    }
    
    func selectContactViewControllerDidRequestManualInput(_ controller: SelectContactViewController) {
        let viewModel = ContactQuestionnaireViewModel(task: task, questionnaire: questionnaire)
        let detailsController = ContactQuestionnaireViewController(viewModel: viewModel)
        detailsController.delegate = self
        
        navigationController.pushViewController(detailsController, animated: true)
    }
    
    func selectContactViewControllerDidCancel(_ controller: SelectContactViewController) {
        updatedTask = nil
        navigationController.dismiss(animated: true)
    }
    
}

extension SelectContactCoordinator: ContactQuestionnaireViewControllerDelegate {
    
    func contactQuestionnaireViewControllerDidCancel(_ controller: ContactQuestionnaireViewController) {
        updatedTask = nil
        navigationController.dismiss(animated: true)
    }
    
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, didSave contactTask: Task) {
        updatedTask = contactTask
        navigationController.dismiss(animated: true)
    }
    
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, wantsToOpen url: URL) {
        UIApplication.shared.open(url)
    }
    
}

extension SelectContactCoordinator: CNContactPickerDelegate {
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        delegate?.selectContactCoordinatorDidCancel(self)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true) {
            let viewModel = ContactQuestionnaireViewModel(task: self.task, questionnaire: self.questionnaire, contact: contact, showCancelButton: true)
            let editController = ContactQuestionnaireViewController(viewModel: viewModel)
            editController.delegate = self
            
            self.presentNavigationController(with: editController)
        }
    }
    
}
