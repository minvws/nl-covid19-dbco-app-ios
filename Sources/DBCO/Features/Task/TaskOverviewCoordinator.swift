/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol TaskOverviewCoordinatorDelegate: class {
    func taskOverviewCoordinatorDidRequestReset(_ coordinator: TaskOverviewCoordinator)
}

/// Coordinator displaying the tasks for the index with [TaskOverviewViewController](x-source-tag://TaskOverviewViewController).
/// Uses [SelectContactCoordinator](x-source-tag://SelectContactCoordinator) and [EditContactCoordinator](x-source-tag://EditContactCoordinator) for updating tasks.
/// Uses [UploadCoordinator](x-source-tag://UploadCoordinator) to upload the tasks.
///
/// - Tag: TaskOverviewCoordinator
final class TaskOverviewCoordinator: Coordinator, Logging {
    var loggingCategory: String = "TaskOverviewCoordinator"
    
    private weak var delegate: TaskOverviewCoordinatorDelegate?
    
    private let window: UIWindow
    private let overviewController: TaskOverviewViewController
    private let navigationController: NavigationController
    
    init(window: UIWindow, delegate: TaskOverviewCoordinatorDelegate) {
        self.window = window
        self.delegate = delegate
        
        let viewModel = TaskOverviewViewModel()
        
        overviewController = TaskOverviewViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: overviewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        super.init()
        
        overviewController.delegate = self
    }
    
    override func start() {
        if window.rootViewController == nil {
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        } else {
            let snapshotView = window.snapshotView(afterScreenUpdates: true)!
            
            window.rootViewController = navigationController
            navigationController.view.addSubview(snapshotView)
            
            UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromRight]) {
                snapshotView.removeFromSuperview()
            }
        }
        
        // If initial loading of case data failed try again here and present the user with an error when the request fails again.
        func loadCaseDataIfNeeded() {
            guard !Services.caseManager.hasCaseData else { return }
            
            Services.caseManager.loadCaseData { success, error in
                if !success {
                    showLoadingError()
                }
            }
        }
        
        func showLoadingError() {
            let alert = UIAlertController(title: .taskLoadingErrorTitle, message: .taskLoadingErrorMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .tryAgain, style: .default) { _ in
                loadCaseDataIfNeeded()
            })
            
            navigationController.present(alert, animated: true)
        }
        
        loadCaseDataIfNeeded()
    }
    
    private func upload() {
        guard Services.caseManager.hasCaseData else {
            return
        }
        
        startChildCoordinator(UploadCoordinator(presenter: overviewController, delegate: self))
    }
    
    private func selectContact(for task: Task) {
        guard Services.caseManager.hasCaseData else { return }
        
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }
    
    private func addContact() {
        guard Services.caseManager.hasCaseData else {
            logWarning("Cannot add contact before case data is fetched")
            return
        }
        
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: nil, delegate: self))
    }
    
    private func editContact(for task: Task) {
        guard Services.caseManager.hasCaseData else { return }
        
        startChildCoordinator(EditContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }

}

// MARK: - Coordinator delegates
extension TaskOverviewCoordinator: SelectContactCoordinatorDelegate {

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

extension TaskOverviewCoordinator: EditContactCoordinatorDelegate {
    
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

extension TaskOverviewCoordinator: UploadCoordinatorDelegate {
    
    func uploadCoordinatorDidFinish(_ coordinator: UploadCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

// MARK: - ViewController delegates
extension TaskOverviewCoordinator: TaskOverviewViewControllerDelegate {
    
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
    
    func taskOverviewViewControllerDidRequestDebugMenu(_ controller: TaskOverviewViewController) {
        func confirmReset() {
            let alert = UIAlertController(title: "Are you sure you want to reset?", message: nil, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes, reset!", style: .destructive) { _ in
                self.delegate?.taskOverviewCoordinatorDidRequestReset(self)
            })
            
            alert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))
            
            controller.present(alert, animated: true)
        }
        
        
        var actions = [UIAlertAction]()
        
        if let shareLogs = Bundle.main.infoDictionary?["SHARE_LOGS_ENABLED"] as? String, shareLogs == "YES" {
            actions.append(.init(title: "Share logs", style: .default) { _ in
                let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                                      applicationActivities: nil)
                controller.present(activityViewController, animated: true, completion: nil)
            })
        }
        
        if let resetEnabled = Bundle.main.infoDictionary?["RESET_ENABLED"] as? String, resetEnabled == "YES" {
            actions.append(.init(title: "Reset pairing and data", style: .destructive) { _ in
                confirmReset()
            })
        }
        
        guard !actions.isEmpty else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actions.forEach(alert.addAction)
        alert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))
        
        controller.present(alert, animated: true)
    }
    
}
