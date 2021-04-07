/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DetermineContagiousPeriodCoordinatorDelegate: class {
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith testDate: Date)
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [Symptom], dateOfSymptomOnset: Date)
    func determineContagiousPeriodCoordinatorDidCancel(_ coordinator: DetermineContagiousPeriodCoordinator)
}

final class DetermineContagiousPeriodCoordinator: Coordinator, Logging {
    private let navigationController: UINavigationController
    
    private var testDate = Date.distantPast
    private var symptomOnsetDate = Date.distantPast
    private var symptoms = [Symptom]()
    
    weak var delegate: DetermineContagiousPeriodCoordinatorDelegate?
    
    private enum StepIdentifiers: Int {
        case confirmNoSymptoms = 10001
        case confirmSymptomOnset = 10002
    }
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        
        super.init()
    }
    
    override func start() {
        let viewModel = SelectSymptomsViewModel(continueWithSymptomsButtonTitle: .next,
                                                continueWithoutSymptomsButtonTitle: .contagiousPeriodNoSymptomsButton)
        let symptomController = SelectSymptomsViewController(viewModel: viewModel)
        symptomController.delegate = self
        symptomController.onPopped = { [weak self] _ in
            guard let self = self else { return }
            
            self.delegate?.determineContagiousPeriodCoordinatorDidCancel(self)
        }
        
        navigationController.pushViewController(symptomController, animated: true)
    }
}

extension DetermineContagiousPeriodCoordinator: SelectSymptomsViewControllerDelegate {
    
    private var onsetDatePickerViewModel: OnboardingDateViewModel {
        return .init(
            title: .contagiousPeriodSelectOnsetDateTitle,
            subtitle: .contagiousPeriodSelectOnsetDateMessage,
            date: Services.onboardingManager.contagiousPeriod.symptomOnsetDate,
            actions: [
                .init(type: .secondary, title: .contagiousPeriodSelectOnsetDateHelpButtonTitle, action: symptomOnsetHelp),
                .init(type: .primary, title: .next, action: handleSymptomOnsetDate)
            ])
    }
    
    private var testDatePickerViewModel: OnboardingDateViewModel {
        return .init(
            title: .contagiousPeriodSelectTestDateTitle,
            subtitle: .contagiousPeriodSelectTestDateMessage,
            date: Services.onboardingManager.contagiousPeriod.testDate,
            actions: [
                .init(type: .primary, title: .next, action: handleTestDate)
            ])
    }
    
    func selectSymptomsViewController(_ controller: SelectSymptomsViewController, didSelect symptoms: [Symptom]) {
        let viewModel: OnboardingDateViewModel
        
        if symptoms.isEmpty {
            self.symptoms = []
            viewModel = testDatePickerViewModel
        } else {
            self.symptoms = symptoms
            viewModel = onsetDatePickerViewModel
        }
        
        navigationController.pushViewController(OnboardingDateViewController(viewModel: viewModel), animated: true)
    }
    
}

extension DetermineContagiousPeriodCoordinator: StepViewControllerDelegate {
    
    func stepViewControllerDidSelectPrimaryButton(_ controller: StepViewController) {
        guard let identifier = StepIdentifiers(rawValue: controller.view.tag) else {
            logError("No valid identifier set for onboarding step controller: \(controller)")
            return
        }
        
        switch identifier {
        case .confirmNoSymptoms:
            userConfirmedNoSymptoms()
        case .confirmSymptomOnset:
            userConfirmedDateOfSymptomOnset()
        }
    }
    
    func stepViewControllerDidSelectSecondaryButton(_ controller: StepViewController) {
        guard let identifier = StepIdentifiers(rawValue: controller.view.tag) else {
            logError("No valid identifier set for onboarding step controller: \(controller)")
            return
        }
        
        switch identifier {
        case .confirmNoSymptoms:
            userDidHaveSymptoms()
        case .confirmSymptomOnset:
            userSelectedDayEarlier()
        }
    }
    
}

extension DetermineContagiousPeriodCoordinator {
    
    private func userConfirmedNoSymptoms() {
        delegate?.determineContagiousPeriodCoordinator(self, didFinishWith: testDate)
    }
    
    private func userDidHaveSymptoms() {
        // User changed their mind, go back to symptom selection
        if let symptomController = navigationController.viewControllers.first(where: { $0 is SelectSymptomsViewController }) {
            navigationController.popToViewController(symptomController, animated: true)
        }
    }
    
    private func userConfirmedDateOfSymptomOnset() {
        delegate?.determineContagiousPeriodCoordinator(self, didFinishWith: symptoms, dateOfSymptomOnset: symptomOnsetDate)
    }
    
    private func userSelectedDayEarlier() {
        // Adjust the date to one day earlier
        let adjustedDate = symptomOnsetDate.dateByAddingDays(-1)
        
        let dateViewController = navigationController
            .viewControllers
            .compactMap { $0 as? OnboardingDateViewController }
            .last!
        
        delay(0.4) {
            dateViewController.selectDate(adjustedDate)
        }
        
        navigationController.popToViewController(dateViewController, animated: true)
    }
    
}

// MARK: - TestDate selection handling
extension DetermineContagiousPeriodCoordinator {
    func handleTestDate(_ date: Date) {
        testDate = date
        
        let viewModel = StepViewModel(image: UIImage(named: "Onboarding3")!,
                                                title: .contagiousPeriodNoSymptomsVerifyTitle,
                                                message: .contagiousPeriodNoSymptomsVerifyMessage,
                                                primaryButtonTitle: .contagiousPeriodNoSymptomsVerifyConfirmButton,
                                                secondaryButtonTitle: .contagiousPeriodNoSymptomsVerifyCancelButton,
                                                showSecondaryButtonOnTop: true)
        let stepController = StepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.confirmNoSymptoms.rawValue
        stepController.delegate = self
        
        navigationController.pushViewController(stepController, animated: true)
    }
    
}

// MARK: - OnsetDate selection handling
extension DetermineContagiousPeriodCoordinator {
    func handleSymptomOnsetDate(_ date: Date) {
        if date.numberOfDaysAgo > 14 {
            verifyTwoWeeksAgoReason(for: date)
        } else {
            verifySelectedOnsetDate(date)
        }
    }
    
    func symptomOnsetHelp(_ date: Date) {
        let viewModel = OnsetHelpViewModel()
        let helpController = OnsetHelpViewController(viewModel: viewModel)
        helpController.delegate = self
        
        let wrapperController = NavigationController(rootViewController: helpController)
        
        navigationController.present(wrapperController, animated: true)
    }
    
    private func verifySelectedOnsetDate(_ date: Date) {
        symptomOnsetDate = date
        let verifyDate = date.dateByAddingDays(-1)
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = .contagiousPeriodOnsetDateVerifyDateFormat
        
        let dateString = dateFormatter.string(from: verifyDate)
        
        let viewModel = StepViewModel(image: UIImage(named: "Onboarding3")!,
                                                title: .contagiousPeriodOnsetDateVerifyTitle(date: dateString),
                                                message: .contagiousPeriodOnsetDateVerifyMessage,
                                                primaryButtonTitle: .contagiousPeriodOnsetDateVerifyConfirmButton,
                                                secondaryButtonTitle: .contagiousPeriodOnsetDateVerifyCancelButton,
                                                showSecondaryButtonOnTop: true)
        let stepController = StepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.confirmSymptomOnset.rawValue
        stepController.delegate = self
        
        navigationController.pushViewController(stepController, animated: true)
    }
}

// MARK: - Distant OnsetDate handling
extension DetermineContagiousPeriodCoordinator {
    
    private func verifyTwoWeeksAgoReason(for date: Date) {
        let viewModel = OnboardingPromptViewModel(
            image: UIImage(named: "Onboarding3"),
            title: .verifyOnsetDateTwoWeeksAgoTitle,
            message: nil,
            actions: [
                .init(type: .secondary, title: .verifyOnsetDateTwoWeeksAgoTestedNegative) { self.determineNegativeTestDate(onset: date, alwaysHasSymptoms: false) },
                .init(type: .secondary, title: .verifyOnsetDateTwoWeeksAgoAlwaysHaveSymptoms) { self.verifySymptomsGettingWorse(onset: date) },
                .init(type: .secondary, title: .verifyOnsetDateTwoWeeksAgoBoth) { self.determineNegativeTestDate(onset: date, alwaysHasSymptoms: true) },
                .init(type: .primary, title: .verifyOnsetDateTwoWeeksAgoNo) { self.verifySelectedOnsetDate(date) }
            ])
        
        let promptController = OnboardingPromptViewController(viewModel: viewModel)
        navigationController.pushViewController(promptController, animated: true)
    }
    
    private func determineNegativeTestDate(onset: Date, alwaysHasSymptoms: Bool) {
        let viewModel = OnboardingDateViewModel(
            title: .determineNegativeTestDateTitle,
            subtitle: .determineNegativeTestDateSubtitle,
            date: nil,
            actions: [
                .init(type: .primary, title: .next) {
                    self.handleNegativeTestDate(onset: onset,
                                                negativeTest: $0,
                                                alwaysHasSymptoms: alwaysHasSymptoms)
                }
            ])
        
        navigationController.pushViewController(OnboardingDateViewController(viewModel: viewModel),
                                                animated: true)
    }
    
    private func handleNegativeTestDate(onset: Date, negativeTest: Date, alwaysHasSymptoms: Bool) {
        let mostRecentDate = [onset, negativeTest].sorted(by: <).last!
        
        if mostRecentDate.numberOfDaysAgo > 14 && alwaysHasSymptoms {
            verifySymptomsGettingWorse(onset: mostRecentDate)
        } else {
            continueWithMostRecentDate(mostRecentDate)
        }
    }
    
    private func verifySymptomsGettingWorse(onset: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = .contagiousPeriodOnsetDateVerifyDateFormat
        
        let dateString = dateFormatter.string(from: onset)
        
        let viewModel = OnboardingPromptViewModel(
            image: nil,
            title: .verifySymptomsGettingWorseTitle(date: dateString),
            message: nil,
            actions: [
                .init(type: .secondary, title: .yes) { self.determineSymptomsIncreasingDate(onset) },
                .init(type: .secondary, title: .no) { self.determinePositiveTestDate(onset) }
            ])
        
        let promptController = OnboardingPromptViewController(viewModel: viewModel)
        navigationController.pushViewController(promptController, animated: true)
    }
    
    private func determineSymptomsIncreasingDate(_ currentOnset: Date) {
        let viewModel = OnboardingDateViewModel(
            title: .determineSymptomsIncreasingDateTitle,
            subtitle: .determineSymptomsIncreasingDateSubtitle,
            date: nil,
            actions: [
                .init(type: .primary, title: .next) { self.continueWithMostRecentDate($0, currentOnset) }
            ])
        
        navigationController.pushViewController(OnboardingDateViewController(viewModel: viewModel),
                                                animated: true)
    }
    
    private func determinePositiveTestDate(_ currentOnset: Date) {
        let viewModel = OnboardingDateViewModel(
            title: .determinePositiveTestDateTitle,
            subtitle: .determinePositiveTestDateSubtitle,
            date: nil,
            actions: [
                .init(type: .primary, title: .next) { self.continueWithMostRecentDate($0, currentOnset) }
            ])
        
        navigationController.pushViewController(OnboardingDateViewController(viewModel: viewModel),
                                                animated: true)
    }
    
    private func continueWithMostRecentDate(_ dates: Date...) {
        let mostRecentDate = dates.sorted(by: <).last!
        
        symptomOnsetDate = mostRecentDate
        userConfirmedDateOfSymptomOnset()
    }
}

extension DetermineContagiousPeriodCoordinator: OnsetHelpViewControllerDelegate {
    
    func onsetHelpViewControllerDidSelectClose(_ controller: OnsetHelpViewController) {
        controller.dismiss(animated: true)
    }

}
