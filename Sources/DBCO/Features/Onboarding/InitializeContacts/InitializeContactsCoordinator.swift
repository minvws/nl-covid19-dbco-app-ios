/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts
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
        case requestContactsAuthorization
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
    
    private func continueToContacts() {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch currentStatus {
        case .authorized:
            continueToRoommates()
        default:
            requestContactsAuthorization()
        }
    }
    
    private func requestContactsAuthorization() {
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding4")!,
                                                title: "Wil je je contactenlijst gebruiken om contactgegevens in te vullen?",
                                                message: "Gebruik je contactenlijst om makkelijk contacten te vinden en contactgegevens in te vullen. Je bepaalt daarna zelf welke gegevens je met de GGD deelt.",
                                                primaryButtonTitle: "Toegang geven",
                                                secondaryButtonTitle: "Handmatig toevoegen",
                                                showSecondaryButtonOnTop: true)
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.requestContactsAuthorization.rawValue
        stepController.delegate = self
        
        navigationController.pushViewController(stepController, animated: true)
    }
    
    private func continueToRoommates() {
        let viewModel = SelectRoommatesViewModel()
        let roommatesController = SelectRoommatesViewController(viewModel: viewModel)
        roommatesController.delegate = self
        
        navigationController.pushViewController(roommatesController, animated: true)
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
            requestPrivacyConsent()
        case .requestContactsAuthorization:
            promptContactsAuthorization()
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
        case .requestContactsAuthorization:
            continueToRoommates()
        }
    }
    
    private func requestPrivacyConsent() {
        let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
        let consentController = PrivacyConsentViewController(viewModel: viewModel)
        consentController.delegate = self
        navigationController.pushViewController(consentController, animated: true)
    }
    
    private func promptContactsAuthorization() {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch currentStatus {
        case .authorized:
            continueToRoommates()
        case .notDetermined:
            CNContactStore().requestAccess(for: .contacts) { authorized, error in
                DispatchQueue.main.async {
                    self.continueToRoommates()
                }
            }
        case .denied, .restricted: fallthrough
        @unknown default:
            // go to settings
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
    
}

extension InitializeContactsCoordinator: PrivacyConsentViewControllerDelegate {
    
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController) {
        if Services.caseManager.hasCaseData {
            continueToContacts()
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
        
        continueToContacts()
        
    }
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [String], dateOfSymptomOnset: Date) {
        // Not removing the coordinator here, so the user can go back and adjust if needed
        
        continueToContacts()
    }
    
    func determineContagiousPeriodCoordinatorDidCancel(_ coordinator: DetermineContagiousPeriodCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension InitializeContactsCoordinator: SelectRoommatesViewControllerDelegate {
    
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didSelect roommates: [String]) {
        
    }
    
}
