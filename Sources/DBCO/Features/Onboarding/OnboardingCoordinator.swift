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

final class OnboardingCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: NavigationController
    private var didPair: Bool = false
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = OnboardingStepViewModel(image: UIImage(named: "StartVisual")!,
                                                title: .onboardingStep1Title,
                                                message: .onboardingStep1Message,
                                                buttonTitle: .next)
        let stepController = OnboardingStepViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: stepController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        if #available(iOS 13.0, *) {
            // nothing
        } else {
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        }
        
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
            let viewModel = PairViewModel()
            let pairController = PairViewController(viewModel: viewModel)
            pairController.delegate = self
            navigationController.pushViewController(pairController, animated: true)
        }
    }
    
}

extension OnboardingCoordinator: PairViewControllerDelegate {
    
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String) {
        controller.startLoadingAnimation()
        navigationController.navigationBar.isUserInteractionEnabled = false
        
        // Fake doing some work for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            controller.stopLoadingAnimation()
            self.navigationController.navigationBar.isUserInteractionEnabled = true
            
            self.didPair = true
            
            let viewModel = OnboardingStepViewModel(image: UIImage(named: "StartVisual")!,
                                                    title: .onboardingStep3Title,
                                                    message: .onboardingStep3Message,
                                                    buttonTitle: .start)
            let stepController = OnboardingStepViewController(viewModel: viewModel)
            stepController.delegate = self
            self.navigationController.setViewControllers([stepController], animated: true)
        }
    }
    
}
