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
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = TaskOverviewViewModel()
        
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
        startChildCoordinator(UploadCoordinator(presenter: overviewController, delegate: self))
    }
    
    private func openHelp() {
        startChildCoordinator(HelpCoordinator(presenter: overviewController, delegate: self))
    }
    
    private func selectContact(for task: Task) {
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }
    
    private func addContact() {
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: nil, delegate: self))
    }
    
    private func editContact(for task: Task) {
        startChildCoordinator(EditContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }
    
    private func informContactIfNeeded(for task: Task) {
        startChildCoordinator(InformContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }

}

// MARK: - Coordinator delegates
extension TaskOverviewCoordinator: HelpCoordinatorDelegate {
    
    func helpCoordinatorDidFinish(_ coordinator: HelpCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: SelectContactCoordinatorDelegate {

    func selectContactCoordinator(_ coordinator: SelectContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        informContactIfNeeded(for: task)
    }
    
    func selectContactCoordinatorDidCancel(_ coordinator: SelectContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: EditContactCoordinatorDelegate {
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishContactTask task: Task) {
        removeChildCoordinator(coordinator)
        informContactIfNeeded(for: task)
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

extension TaskOverviewCoordinator: InformContactCoordinatorDelegate {
    
    func informContactCoordinator(_ coordinator: InformContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        
        Services.taskManager.save(task)
    }
    
}

// MARK: - ViewController delegates
extension TaskOverviewCoordinator: TaskOverviewViewControllerDelegate {
    
    func taskOverviewViewControllerDidRequestHelp(_ controller: TaskOverviewViewController) {
        openHelp()
    }
    
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController) {
        addContact()
    }
    
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task) {
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
    
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController) {
        upload()
    }
    
}
