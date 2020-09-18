/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol SelectContactCoordinatorDelegate: class {
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: CNContact?)
}

final class SelectContactCoordinator: NSObject, Coordinator {
    private weak var delegate: SelectContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private var selectedContact: CNContact?
    
    var children = [Coordinator]()
    
    init(presenter: UIViewController, delegate: SelectContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
    }
    
    func start() {
        let firstController: UIViewController
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        if currentStatus == .authorized {
            let viewModel = SelectContactViewModel()
            let selectController = SelectContactViewController(viewModel: viewModel)
            selectController.delegate = self
            
            firstController = selectController
        } else {
            let viewModel = RequestContactsAuthorizationViewModel(currentStatus: currentStatus)
            let authorizationController = RequestAuthorizationViewController(viewModel: viewModel)
            authorizationController.delegate = self
            
            firstController = authorizationController
        }

        navigationController.setViewControllers([firstController], animated: false)
        presenter?.present(navigationController, animated: true)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.selectContactCoordinatorDidFinish(self, with: self.selectedContact)
        }
    }
    
    func continueAfterAuthorization() {
        let viewModel = SelectContactViewModel()
        let selectController = SelectContactViewController(viewModel: viewModel)
        selectController.delegate = self
        
        navigationController.setViewControllers([selectController], animated: true)
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
        navigationController.dismiss(animated: true)
    }
    
    func currentAutorizationStatus(for controller: RequestAuthorizationViewController) -> AuthorizationStatusConvertible {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
}

extension SelectContactCoordinator: SelectContactViewControllerDelegate {
    
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact) {
        selectedContact = contact
        navigationController.dismiss(animated: true)
    }
    
}
