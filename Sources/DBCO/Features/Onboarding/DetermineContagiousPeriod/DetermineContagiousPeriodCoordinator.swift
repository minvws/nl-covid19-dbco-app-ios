/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DetermineContagiousPeriodCoordinatorDelegate: class {
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith testDate: Date)
    func determineContagiousPeriodCoordinator(_ coordinator: DetermineContagiousPeriodCoordinator, didFinishWith symptoms: [String], dateOfSymptomOnset: Date)
    func determineContagiousPeriodCoordinatorDidCancel(_ coordinator: DetermineContagiousPeriodCoordinator)
}

final class DetermineContagiousPeriodCoordinator: Coordinator, Logging {
    private let navigationController: UINavigationController
    
    private var testDate = Date.distantPast
    private var symptomOnsetDate = Date.distantPast
    private var symptoms = [String]()
    
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
    
    func selectSymptomsViewController(_ controller: SelectSymptomsViewController, didSelect symptoms: [String]) {
        if !symptoms.isEmpty {
            self.symptoms = symptoms
            
            let dateController = SelectSymptomOnsetDateViewController()
            dateController.delegate = self
            
            navigationController.pushViewController(dateController, animated: true)
        } else {
            self.symptoms = []
            
            let dateController = SelectTestDateViewController()
            dateController.delegate = self
            
            navigationController.pushViewController(dateController, animated: true)
        }
    }
    
}

extension DetermineContagiousPeriodCoordinator: OnboardingStepViewControllerDelegate {
    
    func onboardingStepViewControllerDidSelectPrimaryButton(_ controller: OnboardingStepViewController) {
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
    
    func onboardingStepViewControllerDidSelectSecondaryButton(_ controller: OnboardingStepViewController) {
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
        let adjustedDate = Calendar.current.date(byAdding: .day, value: -1, to: symptomOnsetDate)!
        delegate?.determineContagiousPeriodCoordinator(self, didFinishWith: symptoms, dateOfSymptomOnset: adjustedDate)
    }
    
}

extension DetermineContagiousPeriodCoordinator: SelectTestDateViewControllerDelegate {
    
    func selectTestDateViewController(_ controller: SelectTestDateViewController, didSelect date: Date) {
        testDate = date
        
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding3")!,
                                                title: .contagiousPeriodNoSymptomsVerifyTitle,
                                                message: .contagiousPeriodNoSymptomsVerifyMessage,
                                                primaryButtonTitle: .contagiousPeriodNoSymptomsVerifyConfirmButton,
                                                secondaryButtonTitle: .contagiousPeriodNoSymptomsVerifyCancelButton,
                                                showSecondaryButtonOnTop: true)
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.confirmNoSymptoms.rawValue
        stepController.delegate = self
        
        navigationController.pushViewController(stepController, animated: true)
    }
    
}

extension DetermineContagiousPeriodCoordinator: SelectSymptomOnsetDateViewControllerDelegate {
    
    func selectSymptomOnsetDateViewController(_ controller: SelectSymptomOnsetDateViewController, didSelect date: Date) {
        symptomOnsetDate = date
        
        let verifyDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = .contagiousPeriodOnsetDateVerifyDateFormat
        
        let dateString = dateFormatter.string(from: verifyDate)
        
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "Onboarding3")!,
                                                title: .contagiousPeriodOnsetDateVerifyTitle(date: dateString),
                                                message: .contagiousPeriodOnsetDateVerifyMessage,
                                                primaryButtonTitle: .contagiousPeriodOnsetDateVerifyConfirmButton,
                                                secondaryButtonTitle: .contagiousPeriodOnsetDateVerifyCancelButton,
                                                showSecondaryButtonOnTop: true)
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        stepController.view.tag = StepIdentifiers.confirmSymptomOnset.rawValue
        stepController.delegate = self
        
        navigationController.pushViewController(stepController, animated: true)
    }
    
    func selectSymptomOnsetDateViewControllerWantsHelp(_ controller: SelectSymptomOnsetDateViewController) {
        
    }
    
}