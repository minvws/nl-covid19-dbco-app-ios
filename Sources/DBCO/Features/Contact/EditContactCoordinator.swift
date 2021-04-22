/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol EditContactCoordinatorDelegate: class {
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishContactTask task: Task)
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator)
}

/// Coordinator managing the flow of editing a contact task. Presents [ContactQuestionnaireViewController](x-source-tag://ContactQuestionnaireViewController) in a modal fashion.
/// - Tag: EditContactCoordinator
final class EditContactCoordinator: Coordinator, Logging {
    
    let loggingCategory = "EditContactCoordinator"
    
    private weak var delegate: EditContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    private let task: Task
    private var updatedTask: Task?
    
    init(presenter: UIViewController, contactTask: Task, delegate: EditContactCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
        self.task = contactTask
    }
    
    override func start() {
        guard let questionnaire = try? Services.caseManager.questionnaire(for: task.taskType) else {
            logError("Could not get questionnaire for contact task")
            delegate?.editContactCoordinatorDidCancel(self)
            return
        }
        
        let viewModel = ContactQuestionnaireViewModel(task: task, questionnaire: questionnaire)
        let editController = ContactQuestionnaireViewController(viewModel: viewModel)
        editController.delegate = self

        navigationController.setViewControllers([editController], animated: false)
        presenter?.present(navigationController, animated: true)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            if let task = self.updatedTask {
                self.delegate?.editContactCoordinator(self, didFinishContactTask: task)
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
    
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, didSave contactTask: Task) {
        self.updatedTask = contactTask
        navigationController.dismiss(animated: true)
    }
    
    func contactQuestionnaireViewController(_ controller: ContactQuestionnaireViewController, wantsToOpen url: URL) {
        UIApplication.shared.open(url)
    }
    
}
