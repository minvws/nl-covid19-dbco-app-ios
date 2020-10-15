/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

final class TaskOverviewCoordinator: Coordinator {
    private let window: UIWindow
    private let overviewController: TaskOverviewViewController
    private let navigationController: NavigationController
    private let taskManager: TaskManager
    
    init(window: UIWindow, taskManager: TaskManager) {
        self.window = window
        self.taskManager = taskManager
        
        let viewModel = TaskOverviewViewModel(taskManager: taskManager)
        
        overviewController = TaskOverviewViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: overviewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        super.init()
        
        overviewController.delegate = self
    }
    
    override func start() {
        let snapshotView = window.snapshotView(afterScreenUpdates: true)!
        
        window.rootViewController = navigationController
        navigationController.view.addSubview(snapshotView)
        
        UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromRight]) {
            snapshotView.removeFromSuperview()
        }
    }
    
    private func upload() {
        startChildCoordinator(UploadCoordinator(presenter: overviewController, taskManager: taskManager, delegate: self))
    }
    
    private func openHelp() {
        startChildCoordinator(HelpCoordinator(presenter: overviewController, delegate: self))
    }
    
    private func selectContact(suggestedName: String?, for task: Task? = nil) {
        startChildCoordinator(
            SelectContactCoordinator(presenter: overviewController, suggestedName: suggestedName, delegate: self),
            context: task)
    }
    
    private func editContact(contact: OldContact, for task: Task) {
        startChildCoordinator(
            EditContactCoordinator(presenter: overviewController, contact: contact, delegate: self),
            context: task)
    }

}

// MARK: - Coordinator delegates
extension TaskOverviewCoordinator: HelpCoordinatorDelegate {
    
    func helpCoordinatorDidFinish(_ coordinator: HelpCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: OldContact?) {
        removeChildCoordinator(coordinator)
        
        guard let contact = contact else {
            return
        }
        
        if let task = coordinator.context as? Task {
            taskManager.setContact(contact, for: task)
        } else {
            taskManager.addContact(contact)
        }
    }
    
}

extension TaskOverviewCoordinator: EditContactCoordinatorDelegate {
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishEditing contact: OldContact) {
        removeChildCoordinator(coordinator)
        
        if let task = coordinator.context as? Task {
            taskManager.setContact(contact, for: task)
        }
    }
    
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: UploadCoordinatorDelegate {
    
    func uploadCoordinatorDidFinish(_ coordinator: UploadCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

// MARK: - ViewController delegates
extension TaskOverviewCoordinator: TaskOverviewViewControllerDelegate {
    
    func taskOverviewViewControllerDidRequestHelp(_ controller: TaskOverviewViewController) {
        openHelp()
    }
    
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController) {
        selectContact(suggestedName: nil)
    }
    
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task) {
        switch task.taskType {
        case .contact:
//            if let contact = contactDetailsTask.contact {
//                // edit flow
//                editContact(contact: contact, for: contactDetailsTask)
//            } else {
//                // pick flow
//                selectContact(suggestedName: contactDetailsTask.name, for: contactDetailsTask)
//            }
            break
        default:
            break
        }
    }
    
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController) {
        upload()
    }
    
}
