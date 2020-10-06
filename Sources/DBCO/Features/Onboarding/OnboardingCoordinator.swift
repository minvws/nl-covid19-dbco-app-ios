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
        
        navigationController.delegate = self
        startController.delegate = self
    }
    
    override func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

}

extension OnboardingCoordinator: UINavigationControllerDelegate {
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
}

extension OnboardingCoordinator: StartViewControllerDelegate {
    
    func startViewControllerWantsToContinue(_ controller: StartViewController) {
        let viewModel = PairViewModel()
        let pairController = PairViewController(viewModel: viewModel)
        pairController.delegate = self
        navigationController.pushViewController(pairController, animated: true)
    }
    
}

extension OnboardingCoordinator: PairViewControllerDelegate {
    
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String) {
        controller.startLoadingAnimation()
        
        // Fake doing some work for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            controller.stopLoadingAnimation()
        }
    }
    
}
