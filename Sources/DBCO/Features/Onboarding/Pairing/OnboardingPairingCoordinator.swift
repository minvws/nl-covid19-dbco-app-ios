/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import SafariServices

protocol OnboardingPairingCoordinatorDelegate: AnyObject {
    func onboardingPairingCoordinatorDidFinish(_ coordinator: OnboardingPairingCoordinator)
    func onboardingPairingCoordinatorDidCancel(_ coordinator: OnboardingPairingCoordinator)
}

/// Coordinator managing pairing with the backend during onboarding.
/// Uses [PairViewController](x-source-tag://PairViewController) and [PrivacyConsentViewController](x-source-tag://PrivacyConsentViewController)
///
/// - Tag: OnboardingPairingCoordinator
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
    
    @objc private func continueToPairing() {
        let pairingController = PairViewController(viewModel: PairViewModel())
        pairingController.delegate = self
        
        navigationController.pushViewController(pairingController, animated: true)
    }
    
    @objc private func finish() {
        delegate?.onboardingPairingCoordinatorDidFinish(self)
    }

}

extension OnboardingPairingCoordinator: PairViewControllerDelegate {
    
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String) {
        pair(code: code, controller: controller)
    }
    
}

// MARK: - Pairing logic
extension OnboardingPairingCoordinator {
    
    private func pair(code: String, controller: PairViewController) {
        controller.startLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = false
        
        Services.pairingManager.pair(pairingCode: code) { [unowned self] success, error in
            if success {
                loadCaseData(code: code, controller: controller)
            } else {
                pairErrorAlert(code: code, controller: controller)
            }
        }
    }
    
    private func pairErrorAlert(code: String, controller: PairViewController) {
        controller.stopLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = true
        
        let alert = UIAlertController(title: .onboardingLoadingErrorTitle, message: .onboardingLoadingErrorMessage, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .onboardingLoadingErrorCancelAction, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: .onboardingLoadingErrorRetryAction, style: .default) { [unowned self] _ in
            pair(code: code, controller: controller)
        })
        
        if let shareLogs = Bundle.main.infoDictionary?["SHARE_LOGS_ENABLED"] as? String, shareLogs == "YES" {
            alert.addAction(UIAlertAction(title: "Share logs", style: .default) { _ in
                let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                                      applicationActivities: nil)
                controller.present(activityViewController, animated: true, completion: nil)
            })
        }
        
        controller.present(alert, animated: true)
    }
    
    private func loadCaseData(code: String, controller: PairViewController) {
        controller.startLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = false
        
        Services.caseManager.loadCaseData(userInitiated: true) { [unowned self] success, error in
            if success {
                finishPairing(controller: controller)
            } else if case .couldNotLoadQuestionnaires = error {
                // If only the questionnaires could not be loaded:
                finishPairing(controller: controller)
            } else {
                caseErrorAlert(code: code, controller: controller)
            }
        }
    }
    
    private func caseErrorAlert(code: String, controller: PairViewController) {
        controller.stopLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = false
        
        let alert = UIAlertController(title: .taskLoadingErrorTitle, message: .taskLoadingErrorMessage, preferredStyle: .alert)
        
        if let shareLogs = Bundle.main.infoDictionary?["SHARE_LOGS_ENABLED"] as? String, shareLogs == "YES" {
            alert.addAction(UIAlertAction(title: "Share logs", style: .default) { _ in
                let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                                      applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { [unowned self] _, _, _, _ in loadCaseData(code: code, controller: controller) }
                controller.present(activityViewController, animated: true, completion: nil)
            })
        }
        
        alert.addAction(UIAlertAction(title: .onboardingLoadingErrorRetryAction, style: .default) { [unowned self] _ in
            loadCaseData(code: code, controller: controller)
        })
        
        controller.present(alert, animated: true)
    }
    
    private func finishPairing(controller: PairViewController) {
        controller.stopLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = true
    
        let viewModel = StepViewModel(
            image: UIImage(named: "Onboarding2"),
            title: .onboardingPairingIntroTitle,
            message: .onboardingPairingIntroMessage,
            actions: [
                .init(type: .primary, title: .next, target: self, action: #selector(finish))
            ])

        let stepController = StepViewController(viewModel: viewModel)

        navigationController.setViewControllers([stepController], animated: true)
    }
}
