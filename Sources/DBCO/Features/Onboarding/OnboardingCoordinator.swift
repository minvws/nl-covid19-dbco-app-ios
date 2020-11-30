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

/// Coordinator managing the onboarding of the user and pairing with the backend. Temporarily also fetches the tasks and questionnaires.
/// Uses [PairViewController](x-source-tag://PairViewController) and [OnboardingStepViewController](x-source-tag://OnboardingStepViewController)
final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: NavigationController
    private var didPair: Bool = false
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding1")!,
                                                title: .onboardingStep1Title,
                                                message: .onboardingStep1Message,
                                                buttonTitle: .next)
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
    
    func onboardingStepViewControllerWantsToContinue(_ controller: OnboardingStepViewController) {
        if didPair {
            delegate?.onboardingCoordinatorDidFinish(self)
        } else {
            let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
            let consentController = PrivacyConsentViewController(viewModel: viewModel)
            consentController.delegate = self
            navigationController.pushViewController(consentController, animated: true)
        }
    }
    
}

extension OnboardingCoordinator: PrivacyConsentViewControllerDelegate {
    
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController) {
        let viewModel = PairViewModel()
        let pairController = PairViewController(viewModel: viewModel)
        pairController.delegate = self
        navigationController.pushViewController(pairController, animated: true)
    }
    
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL) {
        UIApplication.shared.open(url)
    }
    
}

extension OnboardingCoordinator: PairViewControllerDelegate {
    
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String) {
        controller.startLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = false
    
        func errorAlert() {
            controller.stopLoadingAnimation()
            self.navigationController.navigationBar.isUserInteractionEnabled = true
            
            let alert = UIAlertController(title: .onboardingLoadingErrorTitle, message: .onboardingLoadingErrorMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .ok, style: .default, handler: nil))
            
            controller.present(alert, animated: true)
        }
        
        func pair(pairdingCode: String) {
            Services.pairingManager.pair(pairingCode: code) { success, error in
                if success {
                    finish()
                } else {
                    errorAlert()
                }
            }
        }
        
        func finish() {
            controller.stopLoadingAnimation()
            self.navigationController.navigationBar.isUserInteractionEnabled = true
            
            self.didPair = true
            
            let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding2")!,
                                                    title: .onboardingStep3Title,
                                                    message: .onboardingStep3Message,
                                                    buttonTitle: .start)
            let stepController = OnboardingStepViewController(viewModel: viewModel)
            stepController.delegate = self
            self.navigationController.setViewControllers([stepController], animated: true)
            
            // Load case data. If it fails, the task overview will try again.
            Services.caseManager.loadCaseData(userInitiated: false, completion: { _, _ in })
        }
        
        pair(pairdingCode: code)
    }
    
}
