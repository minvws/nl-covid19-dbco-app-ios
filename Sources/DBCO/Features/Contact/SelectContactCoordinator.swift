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
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: Contact?)
}

final class SelectContactCoordinator: Coordinator {
    
    private weak var delegate: SelectContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private var selectedContact: Contact?
    private var suggestedName: String?
    
    init(presenter: UIViewController, suggestedName: String? = nil, delegate: SelectContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.suggestedName = suggestedName
    }
    
    override func start() {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch currentStatus {
        case .authorized:
            let viewModel = SelectContactViewModel(suggestedName: suggestedName)
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
                    self.delegate?.selectContactCoordinatorDidFinish(self, with: nil)
                })
            
            presenter?.present(actionSheet, animated: true)
        }
    }
    
    private func presentNavigationController(with controller: UIViewController) {
        navigationController.setViewControllers([controller], animated: false)
        presenter?.present(navigationController, animated: true)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.selectContactCoordinatorDidFinish(self, with: self.selectedContact)
        }
    }
    
    private func continueAfterAuthorization() {
        let viewModel = SelectContactViewModel(suggestedName: suggestedName)
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
        let contact = Contact(type: .general, name: suggestedName ?? "")
        let editViewModel = EditContactViewModel(contact: contact, showCancelButton: true)
        let editController = EditContactViewController(viewModel: editViewModel)
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
        let detailViewModel = EditContactViewModel(contact: Contact(type: .general, name: suggestedName ?? ""), showCancelButton: true)
        let detailsController = EditContactViewController(viewModel: detailViewModel)
        detailsController.delegate = self
        
        navigationController.setViewControllers([detailsController], animated: true)
    }
    
    func currentAutorizationStatus(for controller: RequestAuthorizationViewController) -> AuthorizationStatusConvertible {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
}

extension SelectContactCoordinator: SelectContactViewControllerDelegate {
    
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact) {
        let detailViewModel = EditContactViewModel(contact: contact)
        let detailsController = EditContactViewController(viewModel: detailViewModel)
        detailsController.delegate = self
        
        navigationController.pushViewController(detailsController, animated: true)
    }
    
    func selectContactViewControllerDidRequestManualInput(_ controller: SelectContactViewController) {
        let detailViewModel = EditContactViewModel(contact: Contact(type: .general, name: suggestedName ?? ""))
        let detailsController = EditContactViewController(viewModel: detailViewModel)
        detailsController.delegate = self
        
        navigationController.pushViewController(detailsController, animated: true)
    }
    
    func selectContactViewControllerDidCancel(_ controller: SelectContactViewController) {
        selectedContact = nil
        navigationController.dismiss(animated: true)
    }
    
}

extension SelectContactCoordinator: EditContactViewControllerDelegate {
    
    func editContactViewControllerDidCancel(_ controller: EditContactViewController) {
        selectedContact = nil
        navigationController.dismiss(animated: true)
    }
    
    func editContactViewController(_ controller: EditContactViewController, didSave contact: Contact) {
        selectedContact = contact
        navigationController.dismiss(animated: true)
    }
    
}

extension SelectContactCoordinator: CNContactPickerDelegate {
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        delegate?.selectContactCoordinatorDidFinish(self, with: nil)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true) {
            let editViewModel = EditContactViewModel(contact: contact, showCancelButton: true)
            let editController = EditContactViewController(viewModel: editViewModel)
            editController.delegate = self
            
            self.presentNavigationController(with: editController)
        }
    }
    
}
