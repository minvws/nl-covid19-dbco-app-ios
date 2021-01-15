/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import SafariServices

protocol InitializeContactsCoordinatorDelegate: class {
    func initializeContactsCoordinatorDidFinish(_ coordinator: InitializeContactsCoordinator)
    func initializeContactsCoordinatorDidCancel(_ coordinator: InitializeContactsCoordinator)
}

final class InitializeContactsCoordinator: Coordinator, Logging {
    private let navigationController: UINavigationController
    private let canCancel: Bool
    
    weak var delegate: InitializeContactsCoordinatorDelegate?
    
    private enum StepIdentifiers: Int {
        case start = 10001
    }
    
    init(navigationController: UINavigationController, canCancel: Bool) {
        self.navigationController = navigationController
        self.canCancel = canCancel
        
        super.init()
    }
    
    override func start() {
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding2")!,
                                                title: .onboardingDetermineContactsIntroTitle,
                                                message: .onboardingDetermineContactsIntroMessage,
                                                primaryButtonTitle: .next)
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.start.rawValue
        stepController.delegate = self
        
        if canCancel {
            stepController.onPopped = { [weak self] _ in
                guard let self = self else { return }
                
                self.delegate?.initializeContactsCoordinatorDidCancel(self)
            }
            
            navigationController.pushViewController(stepController, animated: true)
        } else {
            navigationController.setViewControllers([stepController], animated: true)
        }
    }
}

extension InitializeContactsCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerDidSelectPrimaryButton(_ controller: OnboardingStepViewController) {
        guard let identifier = StepIdentifiers(rawValue: controller.view.tag) else {
            logError("No valid identifier set for onboarding step controller: \(controller)")
            return
        }
        
        switch identifier {
        case .start:
            let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
            let consentController = PrivacyConsentViewController(viewModel: viewModel)
            consentController.delegate = self
            navigationController.pushViewController(consentController, animated: true)
        }
    }
    
    func onboardingStepViewControllerDidSelectSecondaryButton(_ controller: OnboardingStepViewController) {
        guard let identifier = StepIdentifiers(rawValue: controller.view.tag) else {
            logError("No valid identifier set for onboarding step controller: \(controller)")
            return
        }
        
        switch identifier {
        case .start:
            break
        }
    }
    
}

extension InitializeContactsCoordinator: PrivacyConsentViewControllerDelegate {
    
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController) {
        if Services.caseManager.hasCaseData {
            // TODO: adding contacts. For now go to the task overview
            delegate?.initializeContactsCoordinatorDidFinish(self)
        } else {
            let contagiousPeriodCoordinator = DetermineContagiousPeriodCoordinator(navigationController: navigationController)
            contagiousPeriodCoordinator.delegate = self
            startChildCoordinator(contagiousPeriodCoordinator)
        }
    }
    
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = Theme.colors.primary
        navigationController.present(safariController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: DetermineContagiousPeriodCoordinatorDelegate {
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith testDate: Date) {
        // Not removing the coordinator here, so the user can go back and adjust if needed
        
        // TODO: adding contacts. For now go to the task overview
        delegate?.initializeContactsCoordinatorDidFinish(self)
        
    }
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [String], dateOfSymptomOnset: Date) {
        // Not removing the coordinator here, so the user can go back and adjust if needed
        
        // TODO: adding contacts. For now go to the task overview
        delegate?.initializeContactsCoordinatorDidFinish(self)
    }
    
    func determineContagiousPeriodCoordinatorDidCancel(_ coordinator: DetermineContagiousPeriodCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}
