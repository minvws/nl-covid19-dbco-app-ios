/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import SafariServices

protocol OnboardingPairingCoordinatorDelegate: class {
    func onboardingPairingCoordinatorDidFinish(_ coordinator: OnboardingPairingCoordinator, hasTasks: Bool)
    func onboardingPairingCoordinatorDidCancel(_ coordinator: OnboardingPairingCoordinator)
}

/// Coordinator managing pairing with the backend during onboarding.
/// Uses [PairViewController](x-source-tag://PairViewController) and [PrivacyConsentViewController](x-source-tag://PrivacyConsentViewController)
final class OnboardingPairingCoordinator: Coordinator {
    private let navigationController: UINavigationController
    
    weak var delegate: OnboardingPairingCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        
        super.init()
    }
    
    override func start() {
        let pairingController = PairViewController(viewModel: PairViewModel())
        pairingController.delegate = self
        pairingController.onPopped = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onboardingPairingCoordinatorDidCancel(self)
        }
        
        navigationController.pushViewController(pairingController, animated: true)
    }
    
    private func continueWithTasks() {
        let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
        let consentController = PrivacyConsentViewController(viewModel: viewModel)
        consentController.delegate = self
        navigationController.setViewControllers([consentController], animated: true)
    }
    
    private func continueWithoutTasks() {
        delegate?.onboardingPairingCoordinatorDidFinish(self, hasTasks: false)
    }

}

extension OnboardingPairingCoordinator: PairViewControllerDelegate {
    
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String) {
        func pair() {
            controller.startLoadingAnimation()
            navigationController.navigationBar.isUserInteractionEnabled = false
            
            Services.pairingManager.pair(pairingCode: code) { success, error in
                if success {
                    loadCaseData()
                } else {
                    pairErrorAlert()
                }
            }
        }
        
        func pairErrorAlert() {
            controller.stopLoadingAnimation()
            navigationController.navigationBar.isUserInteractionEnabled = true
            
            let alert = UIAlertController(title: .onboardingLoadingErrorTitle, message: .onboardingLoadingErrorMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .onboardingLoadingErrorCancelAction, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: .onboardingLoadingErrorRetryAction, style: .default) { _ in
                pair()
            })
            
            controller.present(alert, animated: true)
        }
        
        func loadCaseData() {
            controller.startLoadingAnimation()
            navigationController.navigationBar.isUserInteractionEnabled = false
            
            Services.caseManager.loadCaseData(userInitiated: true) { success, error in
                if success {
                    finish()
                } else if case .couldNotLoadQuestionnaires = error, Services.caseManager.hasCaseData {
                    // If the questionnaire could not be loaded, but the case data is fine, finish()
                    finish()
                } else {
                    caseErrorAlert()
                }
            }
        }
        
        func caseErrorAlert() {
            controller.stopLoadingAnimation()
            navigationController.navigationBar.isUserInteractionEnabled = false
            
            let alert = UIAlertController(title: .onboardingLoadingErrorTitle, message: .onboardingLoadingErrorMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .onboardingLoadingErrorRetryAction, style: .default) { _ in
                loadCaseData()
            })
            
            controller.present(alert, animated: true)
        }
        
        func finish() {
            controller.stopLoadingAnimation()
            navigationController.navigationBar.isUserInteractionEnabled = true
            
            if Services.caseManager.tasks.isEmpty == false {
                continueWithTasks()
            } else {
                continueWithoutTasks()
            }
        }
        
        pair()
    }
    
}

extension OnboardingPairingCoordinator: PrivacyConsentViewControllerDelegate {
    
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController) {
        delegate?.onboardingPairingCoordinatorDidFinish(self, hasTasks: true)
    }
    
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = Theme.colors.primary
        navigationController.present(safariController, animated: true)
    }
    
}
