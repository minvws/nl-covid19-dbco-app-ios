/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol EditContactCoordinatorDelegate: class {
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishEditing contact: OldContact)
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator)
}

final class EditContactCoordinator: Coordinator {
    
    private weak var delegate: EditContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private let contact: OldContact
    private var updatedContact: OldContact?
    
    init(presenter: UIViewController, contact: OldContact, delegate: EditContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.contact = contact
    }
    
    override func start() {
        let viewModel = ContactQuestionnaireViewModel(contact: contact, showCancelButton: true)
        let editController = ContactQuestionnaireViewController(viewModel: viewModel)
        editController.delegate = self

        navigationController.setViewControllers([editController], animated: false)
        presenter?.present(navigationController, animated: true)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            if let contact = self.updatedContact {
                self.delegate?.editContactCoordinator(self, didFinishEditing: contact)
            } else {
                self.delegate?.editContactCoordinatorDidCancel(self)
            }
        }
    }
}

extension EditContactCoordinator: ContactQuestionnaireViewControllerDelegate {
    
    func contactQuestionnaireViewControllerDidCancel(_ controller: ContactQuestionnaireViewController) {
        navigationController.dismiss(animated: true)
    }
    
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, didSave contact: OldContact) {
        self.updatedContact = contact
        navigationController.dismiss(animated: true)
    }
    
}
