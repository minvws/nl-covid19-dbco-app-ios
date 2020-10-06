/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import UIKit

protocol OnboardingCoordinatorDelegate: class {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator)
}

final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: NavigationController
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = StartViewModel()
        let startController = StartViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: startController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        super.init()
        
        startController.delegate = self
    }
    
    override func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

}

extension OnboardingCoordinator: StartViewControllerDelegate {
    
    func onboardingViewControllerWantsToContinue(_ controller: StartViewController) {
        delegate?.onboardingCoordinatorDidFinish(self)
    }
    
}
