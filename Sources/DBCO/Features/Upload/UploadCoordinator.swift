/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol UploadCoordinatorDelegate: class {
    func uploadCoordinatorDidFinish(_ coordinator: UploadCoordinator)
}

class UploadCoordinator: Coordinator {
    
    private weak var delegate: UploadCoordinatorDelegate?
    private weak var presenter: UIViewController?
    
    private let navigationController: NavigationController
    private let taskManager: TaskManager
    
    init(presenter: UIViewController, taskManager: TaskManager, delegate: UploadCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.taskManager = taskManager
    }
    
    override func start() {
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.uploadCoordinatorDidFinish(self)
        }
        
        if taskManager.hasUnfinishedTasks {
            showUnfinishedTasks()
        } else {
            sync(animated: false)
        }
        
        presenter?.present(navigationController, animated: true)
    }
    
    private func showUnfinishedTasks() {
        let viewModel = UnfinishedTasksViewModel(taskManager: taskManager)
        let tasksController = UnfinishedTasksViewController(viewModel: viewModel)
        tasksController.delegate = self
        
        navigationController.setViewControllers([tasksController], animated: false)
    }
    
    private func sync(animated: Bool) {
        navigationController.setViewControllers([LoadingViewController()], animated: animated)
        
        taskManager.sync { _ in
            let viewModel = OnboardingStepViewModel(image: UIImage(named: "StartVisual")!,
                                                    title: "Bedankt voor het delen van de gegevens met de GGD",
                                                    message: "Wil je toch nog contactgegevens aanpassen, contacten toevoegen of een andere wijziging doorgeven dan kan dat.",
                                                    buttonTitle: "Klaar")
            let stepController = OnboardingStepViewController(viewModel: viewModel)
            stepController.delegate = self
            
            self.navigationController.setViewControllers([stepController], animated: true)
        }
    }
    
    private func selectContact(suggestedName: String?, for task: ContactDetailsTask? = nil) {
        startChildCoordinator(
            SelectContactCoordinator(presenter: navigationController, suggestedName: suggestedName, delegate: self),
            context: task)
    }
    
    private func editContact(contact: Contact, for task: ContactDetailsTask) {
        startChildCoordinator(
            EditContactCoordinator(presenter: navigationController, contact: contact, delegate: self),
            context: task)
    }
    
}

extension UploadCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: Contact?) {
        removeChildCoordinator(coordinator)
        
        guard let contact = contact else {
            return
        }
        
        if let task = coordinator.context as? ContactDetailsTask {
            taskManager.setContact(contact, for: task)
        } else {
            taskManager.addContact(contact)
        }
    }
    
}

extension UploadCoordinator: UnfinishedTasksViewControllerDelegate {
    
    func unfinishedTasksViewController(_ controller: UnfinishedTasksViewController, didSelect task: Task) {
        switch task {
        case let contactDetailsTask as ContactDetailsTask:
            if let contact = contactDetailsTask.contact {
                // edit flow
                editContact(contact: contact, for: contactDetailsTask)
            } else {
                // pick flow
                selectContact(suggestedName: contactDetailsTask.name, for: contactDetailsTask)
            }
        default:
            break
        }
    }
    
    func unfinishedTasksViewControllerDidRequestUpload(_ controller: UnfinishedTasksViewController) {
        sync(animated: true)
    }
    
    func unfinishedTasksViewControllerDidCancel(_ controller: UnfinishedTasksViewController) {
        navigationController.dismiss(animated: true)
    }
    
}

extension UploadCoordinator: EditContactCoordinatorDelegate {
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishEditing contact: Contact) {
        removeChildCoordinator(coordinator)
        
        if let task = coordinator.context as? ContactDetailsTask {
            taskManager.setContact(contact, for: task)
        }
    }
    
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension UploadCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerWantsToContinue(_ controller: OnboardingStepViewController) {
        navigationController.dismiss(animated: true)
    }
    
}


