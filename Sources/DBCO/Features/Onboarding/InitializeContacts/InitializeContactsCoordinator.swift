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
    private let skipIntro: Bool
    
    weak var delegate: InitializeContactsCoordinatorDelegate?
    
    init(navigationController: UINavigationController, skipIntro: Bool) {
        self.navigationController = navigationController
        self.skipIntro = skipIntro
        
        super.init()
    }
    
    override func start() {
        if skipIntro {
            navigationController.setViewControllers([privacyConsentViewController()], animated: true)
        } else {
            let viewModel = VerifyZipCodeViewModel()
            let verifyController = VerifyZipCodeViewController(viewModel: viewModel)
            verifyController.delegate = self
            
            verifyController.onPopped = { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.initializeContactsCoordinatorDidCancel(self)
            }
            
            navigationController.pushViewController(verifyController, animated: true)
        }
    }
    
    @objc private func requestPrivacyConsent() {
        navigationController.pushViewController(privacyConsentViewController(), animated: true)
    }
    
    private func privacyConsentViewController() -> PrivacyConsentViewController {
        let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
        let consentController = PrivacyConsentViewController(viewModel: viewModel)
        consentController.delegate = self
        
        return consentController
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
        let viewModel = ContactsAuthorizationViewModel(contactName: nil, style: .onboarding)
        
        let authorizationController = ContactsAuthorizationViewController(viewModel: viewModel)
        authorizationController.delegate = self
        
        navigationController.pushViewController(authorizationController, animated: true)
    }
    
    private func continueToRoommates() {
        let viewModel = SelectRoommatesViewModel()
        let roommatesController = SelectRoommatesViewController(viewModel: viewModel)
        roommatesController.delegate = self
        
        navigationController.pushViewController(roommatesController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: VerifyZipCodeViewControllerDelegate {
    
    func verifyZipCodeViewController(_ controller: VerifyZipCodeViewController, didFinishWithActiveZipCode: Bool) {
        let message: String
        let buttonText: String
        
        if didFinishWithActiveZipCode {
            message = .onboardingDetermineContactsIntroMessageSupported
            buttonText = .onboardingDetermineContactsIntroButtonSupported
        } else {
            message = .onboardingDetermineContactsIntroMessageUnsupported
            buttonText = .onboardingDetermineContactsIntroButtonUnsupported
        }
        
        let viewModel = StepViewModel(
            image: UIImage(named: "Onboarding2"),
            title: .onboardingDetermineContactsIntroTitle,
            message: message,
            actions: [
                .init(type: .primary, title: buttonText, target: self, action: #selector(requestPrivacyConsent))
            ])
        
        let stepController = StepViewController(viewModel: viewModel)
        navigationController.pushViewController(stepController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: ContactsAuthorizationViewControllerDelegate {
    
    func contactsAuthorizationViewControllerDidSelectAllow(_ controller: ContactsAuthorizationViewController) {
        promptContactsAuthorization()
    }
    
    func contactsAuthorizationViewControllerDidSelectManual(_ controller: ContactsAuthorizationViewController) {
        continueToRoommates()
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
        if Services.caseManager.symptomsKnown == false {
            let contagiousPeriodCoordinator = DetermineContagiousPeriodCoordinator(navigationController: navigationController)
            contagiousPeriodCoordinator.delegate = self
            startChildCoordinator(contagiousPeriodCoordinator)
        } else if Services.caseManager.tasks.isEmpty {
            continueToContacts()
        } else {
            delegate?.initializeContactsCoordinatorDidFinish(self)
        }
    }
    
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = Theme.colors.primary
        navigationController.present(safariController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: DetermineContagiousPeriodCoordinatorDelegate {
    
    private func continueToContactsIfNeeded() {
        // Not removing the coordinator here, so the user can go back and adjust if needed
        if Services.caseManager.tasks.isEmpty {
            continueToContacts()
        } else {
            delegate?.initializeContactsCoordinatorDidFinish(self)
        }
    }
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith testDate: Date) {
        Services.onboardingManager.registerTestDate(testDate)
        
        // Not removing the coordinator here, so the user can go back and adjust if needed
        continueToContactsIfNeeded()
    }
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [Symptom], dateOfSymptomOnset: Date) {
        Services.onboardingManager.registerSymptoms(symptoms, dateOfOnset: dateOfSymptomOnset)
        
        // Not removing the coordinator here, so the user can go back and adjust if needed
        continueToContactsIfNeeded()
    }
    
    func determineContagiousPeriodCoordinatorDidCancel(_ coordinator: DetermineContagiousPeriodCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension InitializeContactsCoordinator: SelectRoommatesViewControllerDelegate {
    
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didFinishWith roommates: [Onboarding.Contact]) {
        Services.onboardingManager.registerRoommates(roommates)
        
        let explanationController = ContactsExplanationViewController(viewModel: .init())
        explanationController.delegate = self
        navigationController.pushViewController(explanationController, animated: true)
    }
    
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didCancelWith roommates: [Onboarding.Contact]) {
        Services.onboardingManager.registerRoommates(roommates)
    }
    
}

extension InitializeContactsCoordinator: ContactsExplanationViewControllerDelegate {
    
    func contactsExplanationViewControllerWantsToContinue(_ controller: ContactsExplanationViewController) {
        let viewModel: ContactsTimelineViewModel
        
        switch Services.onboardingManager.contagiousPeriod {
        case .finishedWithSymptoms(_, let date):
            viewModel = ContactsTimelineViewModel(dateOfSymptomOnset: date)
        case .finishedWithTestDate(let date):
            viewModel = ContactsTimelineViewModel(testDate: date)
        case .undetermined where Services.caseManager.hasCaseData:
            if let date = Services.caseManager.dateOfSymptomOnset {
                viewModel = ContactsTimelineViewModel(dateOfSymptomOnset: date)
            } else if let date = Services.caseManager.dateOfTest {
                viewModel = ContactsTimelineViewModel(testDate: date)
            } else {
                fatalError("Date should exist at this point")
            }
            
        default:
            fatalError("Date should exist at this point")
        }
        
        let timelineController = ContactsTimelineViewController(viewModel: viewModel)
        timelineController.delegate = self
        
        navigationController.pushViewController(timelineController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: ContactsTimelineViewControllerDelegate {
    
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [Onboarding.Contact], dateOfSymptomOnset: Date) {
        let onboardingManager = Services.onboardingManager
        
        onboardingManager.registerContacts(contacts)
        
        if case .finishedWithSymptoms(let symptoms, _) = onboardingManager.contagiousPeriod {
            onboardingManager.registerSymptoms(symptoms, dateOfOnset: dateOfSymptomOnset)
        }
        
        delegate?.initializeContactsCoordinatorDidFinish(self)
    }
    
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [Onboarding.Contact], testDate: Date) {
        let onboardingManager = Services.onboardingManager
        
        onboardingManager.registerContacts(contacts)
        onboardingManager.registerTestDate(testDate)
        
        delegate?.initializeContactsCoordinatorDidFinish(self)
    }
    
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didCancelWith contacts: [Onboarding.Contact]) {
        Services.onboardingManager.registerContacts(contacts)
    }
    
    func contactsTimelineViewControllerDidRequestHelp(_ controller: ContactsTimelineViewController) {
        let viewModel = TimelineHelpViewModel()
        let helpController = TimelineHelpViewController(viewModel: viewModel)
        helpController.delegate = self
        
        let wrapperController = NavigationController(rootViewController: helpController)
        
        navigationController.present(wrapperController, animated: true)
    }
    
}

extension InitializeContactsCoordinator: TimelineHelpViewControllerDelegate {
    
    func timelineHelpViewControllerDidSelectClose(_ controller: TimelineHelpViewController) {
        controller.dismiss(animated: true)
    }

}
