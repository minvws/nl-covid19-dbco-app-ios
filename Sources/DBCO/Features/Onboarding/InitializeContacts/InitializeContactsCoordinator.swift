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

extension InitializeContactsCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerDidSelectPrimaryButton(_ controller: OnboardingStepViewController) {
        requestPrivacyConsent()
    }
    
    func onboardingStepViewControllerDidSelectSecondaryButton(_ controller: OnboardingStepViewController) {}
    
    private func requestPrivacyConsent() {
        let viewModel = PrivacyConsentViewModel(buttonTitle: .next)
        let consentController = PrivacyConsentViewController(viewModel: viewModel)
        consentController.delegate = self
        navigationController.pushViewController(consentController, animated: true)
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
        Services.onboardingManager.registerTestDate(testDate)
        
        // Not removing the coordinator here, so the user can go back and adjust if needed
        continueToContacts()
    }
    
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [Symptom], dateOfSymptomOnset: Date) {
        Services.onboardingManager.registerSymptoms(symptoms, dateOfOnset: dateOfSymptomOnset)
        
        // Not removing the coordinator here, so the user can go back and adjust if needed
        continueToContacts()
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
            viewModel = ContactsTimelineViewModel(dateOfSymptomOnset: Services.caseManager.dateOfSymptomOnset)
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
    
}
