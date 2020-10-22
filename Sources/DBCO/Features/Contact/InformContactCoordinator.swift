/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol InformContactCoordinatorDelegate: class {
    func informContactCoordinator(_ coordinator: InformContactCoordinator, didFinishWith task: Task)
}

final class InformContactCoordinator: Coordinator {
    
    private weak var delegate: InformContactCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let task: Task
    
    init(presenter: UIViewController, contactTask: Task, delegate: InformContactCoordinatorDelegate) {
        guard contactTask.taskType == .contact else { fatalError() }
        
        self.delegate = delegate
        self.presenter = presenter
        self.task = contactTask
    }
    
    override func start() {
        if task.contact.didInform {
            delegate?.informContactCoordinator(self, didFinishWith: task)
        } else {
            promptInform()
        }
    }
    
    private func promptInform() {
        let firstName = task.contactFirstName ?? ""
        let alert = UIAlertController(title: .contactInformPromptTitle(firstName: firstName), message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .contantInformOptionDone, style: .default) { _ in
            var updatedTask = self.task
            updatedTask.contact = Task.Contact(category: updatedTask.contact.category,
                                               communication: updatedTask.contact.communication,
                                               didInform: true)
            self.delegate?.informContactCoordinator(self, didFinishWith: updatedTask)
        })
        
        alert.addAction(UIAlertAction(title: .contantInformOptionInformLater, style: .default) { _ in
            self.delegate?.informContactCoordinator(self, didFinishWith: self.task)
        })
        
        alert.addAction(UIAlertAction(title: .contantInformOptionInformNow, style: .default) { _ in
            self.inform()
        })
        
        presenter?.present(alert, animated: true)
    }
    
    private func inform() {
        let activityController = UIActivityViewController(contactTask: task) { [weak self] success in
            guard let self = self else { return }
        
            var updatedTask = self.task
            
            if success {
                updatedTask.contact = Task.Contact(category: updatedTask.contact.category,
                                                   communication: updatedTask.contact.communication,
                                                   didInform: true)
            }
            
            self.delegate?.informContactCoordinator(self, didFinishWith: updatedTask)
        }
        
        presenter?.present(activityController, animated: true)
    }
    
}
