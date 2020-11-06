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

/// Coordinator managing the flow of uploading tasks to the backend.
/// Is very similar to [TaskOverviewCoordinator](x-source-tag://TaskOverviewCoordinator) but only displays unfinished tasks and only allows editing of existing tasks.
/// Uses [UnfinishedTasksViewController](x-source-tag://UnfinishedTasksViewController) to display tasks.
///
/// - Tag: UploadCoordinator
final class UploadCoordinator: Coordinator, Logging {
    
    var loggingCategory: String = "UploadCoordinator"
    
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
        
        if Services.caseManager.hasUnfinishedTasks {
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
        
        do {
            try Services.caseManager.sync { _ in
                let viewModel = OnboardingStepViewModel(image: UIImage(named: "StartVisual")!,
                                                        title: .uploadFinishedTitle,
                                                        message: .uploadFinishedMessage,
                                                        buttonTitle: .done)
                let stepController = OnboardingStepViewController(viewModel: viewModel)
                stepController.delegate = self
                
                self.navigationController.setViewControllers([stepController], animated: true)
            }
        } catch let error {
            logError("Could not sync: \(error)")
        }
    }
    
    private func selectContact(for task: Task) {
        guard Services.caseManager.isPaired else { return }
        
        startChildCoordinator(SelectContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
    private func editContact(for task: Task) {
        guard Services.caseManager.isPaired else { return }
        
        startChildCoordinator(EditContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
}

extension UploadCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinator(_ coordinator: SelectContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        
        do {
            try Services.caseManager.save(task)
        } catch let error {
            logError("Could not save task: \(error)")
        }
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
        
        do {
            try Services.caseManager.save(task)
        } catch let error {
            logError("Could not save task: \(error)")
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


