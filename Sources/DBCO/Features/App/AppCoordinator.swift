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
        LogHandler.setup()
        
        window.tintColor = Theme.colors.primary
        
        let launchCoordinator = LaunchCoordinator(window: window)
        launchCoordinator.delegate = self
        
        startChildCoordinator(launchCoordinator)
    }
    
    private var isUpdatingConfiguration = false
    
    func appWillBecomeVisible() {
        updateConfiguration()
        refreshCaseDataIfNeeded()
        revealContent()
    }
    
    func appDidHide() {
        hideContent()
    }
    
    private func updateConfiguration() {
        guard !isUpdatingConfiguration else { return }
        
        isUpdatingConfiguration = true
        
        Services.configManager.update { [unowned self] updateState, _ in
            switch updateState {
            case .updateRequired(let versionInformation):
                showRequiredUpdate(with: versionInformation)
            case .noActionNeeded:
                break
            }
            
            isUpdatingConfiguration = false
        }
    }
    
    private func refreshCaseDataIfNeeded() {
        Services.caseManager.loadCaseData(userInitiated: false) { _, _ in }
    }
    
    private var privacyProtectionWindow: UIWindow?

    private func hideContent() {
        var sceneWindow: UIWindow?
        
        if #available(iOS 13.0, *) {
            if let scene = window.windowScene {
                sceneWindow = UIWindow(windowScene: scene)
            }
        }
        
        privacyProtectionWindow = sceneWindow ?? UIWindow(frame: UIScreen.main.bounds)
        privacyProtectionWindow?.rootViewController = LaunchViewController(viewModel: .init())
        privacyProtectionWindow?.windowLevel = .alert + 1
        privacyProtectionWindow?.makeKeyAndVisible()
    }
    
    private func revealContent() {
        privacyProtectionWindow?.isHidden = true
        privacyProtectionWindow = nil
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

extension AppCoordinator: LaunchCoordinatorDelegate {
    
    func launchCoordinator(_ coordinator: LaunchCoordinator, needsRequiredUpdate version: AppVersionInformation) {
        showRequiredUpdate(with: version)
    }
    
    func launchCoordinatorDidFinish(_ coordinator: LaunchCoordinator) {
        removeChildCoordinator(coordinator)
        
        if Services.onboardingManager.needsOnboarding {
            let onboardingCoordinator = OnboardingCoordinator(window: window)
            onboardingCoordinator.delegate = self
            startChildCoordinator(onboardingCoordinator)
        } else {
            startChildCoordinator(TaskOverviewCoordinator(window: window, delegate: self))
        }
    }
    
}

extension AppCoordinator: OnboardingCoordinatorDelegate {
    
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator) {
        removeChildCoordinator(coordinator)
        
        startChildCoordinator(TaskOverviewCoordinator(window: window, delegate: self, useFlipTransition: true))
    }
    
}

extension AppCoordinator: AppUpdateViewControllerDelegate {
    
    func appUpdateViewController(_ controller: AppUpdateViewController, wantsToOpen url: URL) {
        UIApplication.shared.open(url)
    }
    
}

extension AppCoordinator: TaskOverviewCoordinatorDelegate {
    
    func taskOverviewCoordinatorDidRequestReset(_ coordinator: TaskOverviewCoordinator) {
    
        Services.pairingManager.unpair()
        try? Services.caseManager.removeCaseData()
        Services.onboardingManager.reset()
        
        removeChildCoordinator(coordinator)
        
        start()
    }
    
}
