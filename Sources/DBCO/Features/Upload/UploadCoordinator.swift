/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol UploadCoordinatorDelegate: AnyObject {
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
    
    private var hasUnfinishedTasks: Bool {
        return !Services.caseManager.tasks.filter(\.isUnfinished).isEmpty
    }
    
    override func start() {
        Services.pairingManager.addListener(self)
        
        if Services.pairingManager.isPaired && !hasUnfinishedTasks {
            showSyncConfirmationAlert(
                presenter: presenter,
                syncHandler: {
                    self.sync(animated: false)
                    self.presenter?.present(self.navigationController, animated: true)
                },
                cancelHandler: {
                    self.delegate?.uploadCoordinatorDidFinish(self)
                })
        } else {
            continueStart()
        }
    }
    
    private func continueStart() {
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.uploadCoordinatorDidFinish(self)
        }
        
        if Services.pairingManager.isPaired {
            continueToUnfinishedTasksOrSync(animated: false)
        } else {
            confirmReadyToPair()
        }
        
        presenter?.present(navigationController, animated: true)
    }
    
    private func continueToUnfinishedTasksOrSync(animated: Bool) {
        if hasUnfinishedTasks {
            showUnfinishedTasks(animated: animated)
        } else {
            sync(animated: animated)
        }
    }
    
    private func showSyncConfirmationAlert(presenter: UIViewController?, syncHandler: @escaping () -> Void, cancelHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: .uploadConfirmAlertTitle, message: .uploadConfirmAlertMessage, preferredStyle: .alert)
        
        alert.addAction(.init(title: .uploadConfirmAlertConfirmButton, style: .default) { _ in
            syncHandler()
        })
        
        alert.addAction(.init(title: .cancel, style: .cancel) { _ in
            cancelHandler()
        })
        
        presenter?.present(alert, animated: true)
    }
    
    private var shouldSkipConfirm: Bool {
        Services.pairingManager.isPollingForPairing ||
        Services.pairingManager.lastPollingError != nil
    }
    
    private func createConfirmViewController() -> UIViewController {
        let viewModel = StepViewModel(
            image: nil,
            title: .reversePairingConfirmTitle,
            message: .reversePairingConfirmMessage,
            actions: [
                .init(type: .primary, title: .yes, target: self, action: #selector(continueToPairing)),
                .init(type: .primary, title: .no, target: self, action: #selector(cancelPairing))
            ],
            hidesNavigationWhenFirst: false)
        
        let stepController = StepViewController(viewModel: viewModel)
        
        if #available(iOS 13.0, *) {
            stepController.isModalInPresentation = true
        }
        
        stepController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: .close, style: .plain, target: self, action: #selector(cancelPairing))
        stepController.title = .reversePairingTitle
        
        return stepController
    }
    
    private func confirmReadyToPair() {
        guard !shouldSkipConfirm else { return pair(animated: false) }
        
        navigationController.setViewControllers([createConfirmViewController()], animated: false)
    }
    
    @objc private func continueToPairing() {
        pair(animated: true)
    }
    
    @objc private func cancelPairing() {
        Services.pairingManager.stopPollingForPairing()
        navigationController.dismiss(animated: true)
    }
    
    private func pair(animated: Bool) {
        let viewModel = ReversePairViewModel(hasUnfinishedTasks: hasUnfinishedTasks)
        let pairingController = ReversePairViewController(viewModel: viewModel)
        pairingController.delegate = self
        
        navigationController.setViewControllers([pairingController], animated: animated)
        
        if let error = Services.pairingManager.lastPollingError {
            Services.pairingManager.lastPairingCode.map { pairingController.applyPairingCode($0) }
            pairingManager(Services.pairingManager, didFailWith: error)
        } else {
            Services.pairingManager.startPollingForPairing()
        }
    }
    
    private func showUnfinishedTasks(animated: Bool) {
        let viewModel = UnfinishedTasksViewModel()
        let tasksController = UnfinishedTasksViewController(viewModel: viewModel)
        tasksController.delegate = self
        
        navigationController.setViewControllers([tasksController], animated: animated)
    }
    
    private func selectContact(for task: Task) {
        guard Services.caseManager.hasCaseData else { return }
        
        startChildCoordinator(SelectContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
    private func editContact(for task: Task) {
        guard Services.caseManager.hasCaseData else { return }
        
        startChildCoordinator(EditContactCoordinator(presenter: navigationController, contactTask: task, delegate: self))
    }
    
}

extension UploadCoordinator {
    
    private func showSyncingError() {
        let alert = UIAlertController(title: .uploadErrorTitle, message: .uploadErrorMessage, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .tryAgain, style: .default) { _ in
            self.attemptSync()
        })
        
        alert.addAction(UIAlertAction(title: .cancel, style: .cancel) { _ in
            self.navigationController.dismiss(animated: true)
        })
        
        navigationController.present(alert, animated: true)
    }
    
    private func attemptSync() {
        do {
            try Services.caseManager.sync { success in
                guard success else { return self.showSyncingError() }
                
                self.continueAfterSyncing()
            }
        } catch let error {
            logError("Could not sync: \(error)")
            showSyncingError()
        }
    }
    
    private func continueAfterSyncing() {
        let viewModel = StepViewModel(
            image: UIImage(named: "UploadSuccess"),
            title: .uploadFinishedTitle,
            message: .uploadFinishedMessage,
            actions: [
                .init(type: .primary, title: .done) { [weak self] in
                    self?.navigationController.dismiss(animated: true)
                }
            ])
        
        let stepController = StepViewController(viewModel: viewModel)
        
        navigationController.setViewControllers([stepController], animated: true)
    }
    
    private func sync(animated: Bool) {
        navigationController.setViewControllers([LoadingViewController()], animated: animated)
        
        attemptSync()
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
            if task.questionnaireResult != nil {
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

extension UploadCoordinator: ReversePairViewControllerDelegate {
    
    func reversePairViewControllerWantsToResumePairing(_ controller: ReversePairViewController) {
        Services.pairingManager.startPollingForPairing()
        controller.clearError()
    }
    
    func reversePairViewControllerWantsToContinue(_ controller: ReversePairViewController) {
        guard hasUnfinishedTasks else {
            showSyncConfirmationAlert(
                presenter: navigationController,
                syncHandler: {
                    self.sync(animated: true)
                },
                cancelHandler: {
                    self.navigationController.dismiss(animated: true)
                })
            
            return
        }
        
        showUnfinishedTasks(animated: true)
    }
    
    func reversePairViewControllerWantsToClose(_ controller: ReversePairViewController) {
        func close() {
            navigationController.dismiss(animated: true)
        }
        
        guard Services.pairingManager.isPollingForPairing else { return close() }
       
        let alertController = UIAlertController(title: .reversePairingCloseAlert,
                                                message: nil,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: .no, style: .default) { _ in
            close()
            Services.pairingManager.stopPollingForPairing()
        })
        
        alertController.addAction(UIAlertAction(title: .yes, style: .default) { _ in
            close()
        })
        
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
}

extension UploadCoordinator: PairingManagerListener {
    
    private var pairViewController: ReversePairViewController? {
        return navigationController.viewControllers.compactMap { $0 as? ReversePairViewController }.first
    }
    
    func pairingManagerDidStartPollingForPairing(_ pairingManager: PairingManaging) {
        pairViewController?.clearPairingCode()
    }
    
    func pairingManager(_ pairingManager: PairingManaging, didFailWith error: PairingManagingError) {
        if pairingManager.canResumePolling {
            pairViewController?.showError()
        } else {
            pairViewController?.showPairingCodeExpired()
        }
    }
    
    func pairingManagerDidCancelPollingForPairing(_ pairingManager: PairingManaging) {}
    
    func pairingManager(_ pairingManager: PairingManaging, didReceiveReversePairingCode code: String) {
        pairViewController?.applyPairingCode(code)
    }
    
    func pairingManagerDidFinishPairing(_ pairingManager: PairingManaging) {
        pairViewController?.showPairingSuccessful()
    }
    
}
