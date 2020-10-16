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

final class SelectContactCoordinator: Coordinator {
    
    private weak var delegate: SelectContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private let task: Task
    private var updatedTask: Task?
    
    init(presenter: UIViewController, contactTask: Task, delegate: SelectContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.task = contactTask
    }
    
    override func start() {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch currentStatus {
        case .authorized:
            let viewModel = SelectContactViewModel(suggestedName: task.label)
            let selectController = SelectContactViewController(viewModel: viewModel)
            selectController.delegate = self
            
            presentNavigationController(with: selectController)
            
        case .notDetermined:
            let viewModel = RequestContactsAuthorizationViewModel(currentStatus: currentStatus)
            let authorizationController = RequestAuthorizationViewController(viewModel: viewModel)
            authorizationController.delegate = self
            
            presentNavigationController(with: authorizationController)
            
        case .denied, .restricted: fallthrough
        @unknown default:
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
        let viewModel = SelectContactViewModel(suggestedName: task.label)
        let selectController = SelectContactViewController(viewModel: viewModel)
        selectController.delegate = self
        
        navigationController.setViewControllers([selectController], animated: true)
    }
    
    private func continueWithSystemContactPicker() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        
        presenter?.present(picker, animated: true)
    }
    
    private func continueManually() {
        let editViewModel = ContactQuestionnaireViewModel(task: task, showCancelButton: true)
        let editController = ContactQuestionnaireViewController(viewModel: editViewModel)
        editController.delegate = self
        
        presentNavigationController(with: editController)
    }
}

extension SelectContactCoordinator: RequestAuthorizationViewControllerDelegate {
    
    func requestAuthorization(for controller: RequestAuthorizationViewController) {
        CNContactStore().requestAccess(for: .contacts) { authorized, error in
            DispatchQueue.main.async {
                if authorized {
                    self.continueAfterAuthorization()
                }
            }
        }
    }
    
    func redirectToSettings(for controller: RequestAuthorizationViewController) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    func continueWithoutAuthorization(for controller: RequestAuthorizationViewController) {
        let editViewModel = ContactQuestionnaireViewModel(task: task, showCancelButton: true)
        let editController = ContactQuestionnaireViewController(viewModel: editViewModel)
        editController.delegate = self
        
        navigationController.setViewControllers([editController], animated: true)
    }
    
    func currentAutorizationStatus(for controller: RequestAuthorizationViewController) -> AuthorizationStatusConvertible {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
}

extension SelectContactCoordinator: SelectContactViewControllerDelegate {
    
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact) {
        let viewModel = ContactQuestionnaireViewModel(task: task, contact: contact)
        let detailsController = ContactQuestionnaireViewController(viewModel: viewModel)
        detailsController.delegate = self
        
        navigationController.pushViewController(detailsController, animated: true)
    }
    
    func selectContactViewControllerDidRequestManualInput(_ controller: SelectContactViewController) {
        let viewModel = ContactQuestionnaireViewModel(task: task)
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
    
}

extension SelectContactCoordinator: CNContactPickerDelegate {
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        delegate?.selectContactCoordinatorDidCancel(self)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true) {
            let viewModel = ContactQuestionnaireViewModel(task: self.task, contact: contact, showCancelButton: true)
            let editController = ContactQuestionnaireViewController(viewModel: viewModel)
            editController.delegate = self
            
            self.presentNavigationController(with: editController)
        }
    }
    
}
