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

// TODO: Update onboarding coordinator documentation
/// Coordinator managing the onboarding of the user, pairing with the backend and guiding the user through the process of creating a list of at-risk contacts.
/// Uses [PairViewController](x-source-tag://PairViewController) and [StepViewController](x-source-tag://StepViewController)
final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: NavigationController
    private var didPair: Bool = false
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        
        let primaryButtonTitle: String
        let secondaryButtonTitle: String?
        
        if Services.configManager.featureFlags.enableSelfBCO {
            primaryButtonTitle = .onboardingStartHasCodeButton
            secondaryButtonTitle = .onboardingStartNoCodeButton
        } else {
            primaryButtonTitle = .next
            secondaryButtonTitle = nil
        }
        
        let viewModel = StepViewModel(image: UIImage(named: "Onboarding1")!,
                                                title: .onboardingStartTitle,
                                                message: .onboardingStartMessage,
                                                primaryButtonTitle: primaryButtonTitle,
                                                secondaryButtonTitle: secondaryButtonTitle)
        let stepController = StepViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: stepController)

        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        super.init()
        
        stepController.delegate = self
    }
    
    override func start() {
        let needsPairingOption = Services.onboardingManager.needsPairingOption
        if needsPairingOption == false {
            let initializeContactsCoordinator = InitializeContactsCoordinator(navigationController: navigationController, skipIntro: true)
            initializeContactsCoordinator.delegate = self
            startChildCoordinator(initializeContactsCoordinator)
        }
        
        window.transition(to: navigationController, with: [.transitionCrossDissolve])
    }
}

extension OnboardingCoordinator: StepViewControllerDelegate {
    
    func stepViewControllerDidSelectPrimaryButton(_ controller: StepViewController) {
        let pairingCoordinator = OnboardingPairingCoordinator(navigationController: navigationController)
        pairingCoordinator.delegate = self
        startChildCoordinator(pairingCoordinator)
    }
    
    func stepViewControllerDidSelectSecondaryButton(_ controller: StepViewController) {
        let initializeContactsCoordinator = InitializeContactsCoordinator(navigationController: navigationController, skipIntro: false)
        initializeContactsCoordinator.delegate = self
        startChildCoordinator(initializeContactsCoordinator)
    }
    
}

extension OnboardingCoordinator: OnboardingPairingCoordinatorDelegate {
    
    func onboardingPairingCoordinatorDidFinish(_ coordinator: OnboardingPairingCoordinator) {
        removeChildCoordinator(coordinator)
        
        let initializeContactsCoordinator = InitializeContactsCoordinator(navigationController: navigationController, skipIntro: true)
        initializeContactsCoordinator.delegate = self
        startChildCoordinator(initializeContactsCoordinator)
    }
    
    func onboardingPairingCoordinatorDidCancel(_ coordinator: OnboardingPairingCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension OnboardingCoordinator: InitializeContactsCoordinatorDelegate {
    
    func initializeContactsCoordinatorDidFinish(_ coordinator: InitializeContactsCoordinator) {
        removeChildCoordinator(coordinator)
        
        // go to task overview
        Services.onboardingManager.finishOnboarding()
        delegate?.onboardingCoordinatorDidFinish(self)
    }
    
    func initializeContactsCoordinatorDidCancel(_ coordinator: InitializeContactsCoordinator) {
        removeChildCoordinator(coordinator)
    }
}
