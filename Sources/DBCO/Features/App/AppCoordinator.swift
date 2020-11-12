/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// The root coordinator of the app. Will present the onboarding if needed and moves to the task overview.
/// Also handles notifying the user of a required update.
final class AppCoordinator: Coordinator {
    private let window: UIWindow
    
    /// For use with iOS 13 and higher
    @available(iOS 13.0, *)
    init(scene: UIWindowScene) {
        window = UIWindow(windowScene: scene)
    }
    
    /// For use with iOS 12.
    override init() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
    }
    
    override func start() {
        #if USERTEST_MOCKS
        Services.use(LocalMockNetworkManager.self)
        #endif
        
        LogHandler.setup()
        
        window.tintColor = Theme.colors.primary
        
        // Check if the app is the minimum version. If not, show the app update screen
        checkForRequiredUpdates()
        
        if Services.caseManager.isPaired {
            startChildCoordinator(TaskOverviewCoordinator(window: window))
        } else {
            let onboardingCoordinator = OnboardingCoordinator(window: window)
            onboardingCoordinator.delegate = self
            startChildCoordinator(onboardingCoordinator)
        }
    }
    
    private var isCheckingForRequiredUpdates = false
    func checkForRequiredUpdates() {
        guard !isCheckingForRequiredUpdates else { return}
        
        isCheckingForRequiredUpdates = true
        
        Services.configManager.checkUpdateRequired { [unowned self] in
            switch $0 {
            case .updateRequired(let versionInformation):
                showRequiredUpdate(with: versionInformation)
            case .noActionNeeded:
                break
            }
            
            isCheckingForRequiredUpdates = false
        }
    }
    
    private func showRequiredUpdate(with versionInformation: AppVersionInformation) {
        guard var topController = window.rootViewController else { return }

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        guard !(topController is AppUpdateViewController) else { return }
        
        let viewModel = AppUpdateViewModel(versionInformation: versionInformation)
        let updateController = AppUpdateViewController(viewModel: viewModel)
        updateController.delegate = self
        
        topController.present(updateController, animated: true)
    }

}

extension AppCoordinator: OnboardingCoordinatorDelegate {
    
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator) {
        removeChildCoordinator(coordinator)
        
        startChildCoordinator(TaskOverviewCoordinator(window: window))
    }
    
}

extension AppCoordinator: AppUpdateViewControllerDelegate {
    
    func appUpdateViewController(_ controller: AppUpdateViewController, wantsToOpen url: URL) {
        UIApplication.shared.open(url)
    }
    
}
