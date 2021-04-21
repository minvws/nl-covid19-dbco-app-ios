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
/// Uses [OnboardingPairingCoordinator](x-source-tag://OnboardingPairingCoordinator) and continues with [InitializeContactsCoordinator](x-source-tag://InitializeContactsCoordinator)
final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private lazy var navigationController: NavigationController = setupNavigationController()
    private var didPair: Bool = false
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        super.init()
    }
    
    private func setupNavigationController() -> NavigationController {
        let primaryButtonTitle: String
        let secondaryButtonTitle: String?
        
        if Services.configManager.featureFlags.enableSelfBCO {
            primaryButtonTitle = .onboardingStartHasCodeButton
            secondaryButtonTitle = .onboardingStartNoCodeButton
        } else {
            primaryButtonTitle = .next
            secondaryButtonTitle = nil
        }
        
        let viewModel = StepViewModel(
            image: UIImage(named: "Onboarding1"),
            title: .onboardingStartTitle,
            message: .onboardingStartMessage,
            actions: [
                .init(type: .primary, title: primaryButtonTitle, target: self, action: #selector(continueToPairing)),
                .init(type: .secondary, title: secondaryButtonTitle, target: self, action: #selector(continueToSelfBCO))
            ])
        
        let stepController = StepViewController(viewModel: viewModel)
        let navigationController = NavigationController(rootViewController: stepController)

        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        return navigationController
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

extension OnboardingCoordinator {
    
    @objc func continueToPairing() {
        let pairingCoordinator = OnboardingPairingCoordinator(navigationController: navigationController)
        pairingCoordinator.delegate = self
        startChildCoordinator(pairingCoordinator)
    }
    
    @objc func continueToSelfBCO() {
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
