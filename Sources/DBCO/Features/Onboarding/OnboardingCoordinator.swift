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

/// Coordinator managing the onboarding of the user, pairing with the backend and guiding the user through the process of creating a list of at-risk contacts.
/// Uses [PairViewController](x-source-tag://PairViewController) and [OnboardingStepViewController](x-source-tag://OnboardingStepViewController)
final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: NavigationController
    private var didPair: Bool = false
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding1")!,
                                                title: "Help de GGD bij het contactonderzoek",
                                                message: "Je kunt via deze app bepalen wie van je contacten een grote kans op besmetting heeft gelopen. Ook kun je contactgegevens met de GGD delen voor het contactonderzoek.",
                                                primaryButtonTitle: "Ik heb al een code",
                                                secondaryButtonTitle: "Ik heb nog geen code")
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: stepController)

        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        super.init()
        
        navigationController.delegate = self
        stepController.delegate = self
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

extension OnboardingCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerDidSelectPrimaryButton(_ controller: OnboardingStepViewController) {
        let pairingCoordinator = OnboardingPairingCoordinator(navigationController: navigationController)
        pairingCoordinator.delegate = self
        startChildCoordinator(pairingCoordinator)
    }
    
    func onboardingStepViewControllerDidSelectSecondaryButton(_ controller: OnboardingStepViewController) {
        let initializeContactsCoordinator = InitializeContactsCoordinator(navigationController: navigationController, canCancel: true)
        initializeContactsCoordinator.delegate = self
        startChildCoordinator(initializeContactsCoordinator)
    }
    
}

extension OnboardingCoordinator: OnboardingPairingCoordinatorDelegate {
    
    func onboardingPairingCoordinatorDidFinish(_ coordinator: OnboardingPairingCoordinator, hasTasks: Bool) {
        removeChildCoordinator(coordinator)
        
        if hasTasks {
            // go to task overview
            delegate?.onboardingCoordinatorDidFinish(self)
        } else {
            let initializeContactsCoordinator = InitializeContactsCoordinator(navigationController: navigationController, canCancel: false)
            initializeContactsCoordinator.delegate = self
            startChildCoordinator(initializeContactsCoordinator)
        }
    }
    
    func onboardingPairingCoordinatorDidCancel(_ coordinator: OnboardingPairingCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension OnboardingCoordinator: InitializeContactsCoordinatorDelegate {
    
    func initializeContactsCoordinatorDidFinish(_ coordinator: InitializeContactsCoordinator) {
        removeChildCoordinator(coordinator)
        
        // go to task overview
        delegate?.onboardingCoordinatorDidFinish(self)
    }
    
    func initializeContactsCoordinatorDidCancel(_ coordinator: InitializeContactsCoordinator) {
        removeChildCoordinator(coordinator)
    }
}
