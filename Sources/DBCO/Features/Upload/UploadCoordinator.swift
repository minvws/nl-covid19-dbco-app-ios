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
    
    init(presenter: UIViewController, delegate: UploadCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
    }
    
    override func start() {
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.uploadCoordinatorDidFinish(self)
        }
        
        if Services.taskManager.hasUnfinishedTasks {
            showUnfinishedTasks()
        } else {
            sync(animated: false)
        }
        
        presenter?.present(navigationController, animated: true)
    }
    
    private func showUnfinishedTasks() {
        let viewModel = UnfinishedTasksViewModel()
        let tasksController = UnfinishedTasksViewController(viewModel: viewModel)
        tasksController.delegate = self
        
        navigationController.setViewControllers([tasksController], animated: false)
    }
    
    private func sync(animated: Bool) {
        navigationController.setViewControllers([LoadingViewController()], animated: animated)
        
        Services.taskManager.sync { _ in
            let viewModel = OnboardingStepViewModel(image: UIImage(named: "StartVisual")!,
                                                    title: "Bedankt voor het delen van de gegevens met de GGD",
                                                    message: "Wil je toch nog contactgegevens aanpassen, contacten toevoegen of een andere wijziging doorgeven dan kan dat.",
                                                    buttonTitle: "Klaar")
            let stepController = OnboardingStepViewController(viewModel: viewModel)
            stepController.delegate = self
            
            self.navigationController.setViewControllers([stepController], animated: true)
        }
    }
    
    private func selectContact(for task: Task) {
        startChildCoordinator(SelectContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
    private func editContact(for task: Task) {
        startChildCoordinator(EditContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
    private func informContactIfNeeded(for task: Task) {
        startChildCoordinator(InformContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
}

extension UploadCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinator(_ coordinator: SelectContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        Services.taskManager.save(task)
    }
    
    func selectContactCoordinatorDidCancel(_ coordinator: SelectContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension UploadCoordinator: UnfinishedTasksViewControllerDelegate {
    
    func unfinishedTasksViewController(_ controller: UnfinishedTasksViewController, didSelect task: Task) {
        switch task.taskType {
        case .contact:
            if task.result != nil {
                // edit flow
                editContact(for: task)
            } else {
                // pick flow
                selectContact(for: task)
            }
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
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishContactTask task: Task) {
        removeChildCoordinator(coordinator)
        informContactIfNeeded(for: task)
    }
    
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension UploadCoordinator: InformContactCoordinatorDelegate {
    
    func informContactCoordinator(_ coordinator: InformContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        
        Services.taskManager.save(task)
    }
    
}

extension UploadCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerWantsToContinue(_ controller: OnboardingStepViewController) {
        navigationController.dismiss(animated: true)
    }
    
}


