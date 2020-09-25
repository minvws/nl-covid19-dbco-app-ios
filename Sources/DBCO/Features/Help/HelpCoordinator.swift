/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol HelpCoordinatorDelegate: class {
    func helpCoordinatorDidFinish(_ coordinator: HelpCoordinator)
}

final class HelpCoordinator: Coordinator {
    private weak var delegate: HelpCoordinatorDelegate?
    private weak var presenter: UIViewController?
    private let navigationController: NavigationController
    
    init(presenter: UIViewController, delegate: HelpCoordinatorDelegate) {
        self.delegate = delegate
        self.presenter = presenter
        self.navigationController = NavigationController()
    }
    
    override func start() {
        let itemManager = HelpItemManager()
        let viewModel = HelpViewModel(helpItems: itemManager.overviewItems)
        let helpController = HelpViewController(viewModel: viewModel)
        helpController.delegate = self
        
        navigationController.setViewControllers([helpController], animated: false)
        
        presenter?.present(navigationController, animated: true, completion: nil)
        
        navigationController.onDismissed = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.helpCoordinatorDidFinish(self)
        }
    }
    
    func push(item: HelpOverviewItem) {
        guard let helpController = navigationController.viewControllers.first as? HelpViewController else { return }
        
        switch item {
        case .question(let question):
            let viewModel = HelpQuestionViewModel(question: question)
            let detailController = HelpQuestionViewController(viewModel: viewModel)
            detailController.delegate = self
        
            navigationController.setViewControllers([helpController, detailController], animated: true)
        }
    }

}

extension HelpCoordinator: HelpViewControllerDelegate {
    
    func helpViewController(_ controller: HelpViewController, didSelect item: HelpOverviewItem) {
        push(item: item)
    }
    
}

extension HelpCoordinator: HelpQuestionViewControllerDelegate {
    
    func helpQuestionViewController(_ controller: HelpQuestionViewController, didSelect item: HelpOverviewItem) {
        push(item: item)
    }
    
}
