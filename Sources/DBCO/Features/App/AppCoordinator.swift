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
        
        _ = resetAppDataIfNeeded()
        
        let launchCoordinator = LaunchCoordinator(window: window)
        launchCoordinator.delegate = self
        
        startChildCoordinator(launchCoordinator)
    }
    
    private func resetAppDataIfNeeded() -> Bool {
        let mostRecentModificationDate =
            [Services.onboardingManager.dataModificationDate,
             Services.caseManager.dataModificationDate]
            .compactMap { $0 }
            .sorted(by: <)
            .last ?? .distantFuture // fallback to future, since there isn't any data to begin with
        
        let twoWeeksAgo = Date.now.dateByAddingDays(-14)
        
        if mostRecentModificationDate < twoWeeksAgo {
            resetData()
            return true
        }
        
        return false
    }
    
    private func resetData() {
        Services.pairingManager.unpair()
        try? Services.caseManager.removeCaseData()
        Services.onboardingManager.reset()
    }
    
    private var isUpdatingConfiguration = false
    
    func appWillBecomeVisible() {
        revealContent()
        
        if resetAppDataIfNeeded() {
            children.forEach(removeChildCoordinator)
            start()
            showResetAlert()
        } else {
            updateConfiguration()
            refreshCaseDataIfNeeded()
        }
    }
    
    func appDidHide() {
        hideContent()
    }
    
    private func showResetAlert() {
        var resetWindow: UIWindow? = createWindow()
        
        let viewModel = StepViewModel(
            image: UIImage(named: "Onboarding1"),
            title: .launchResetAlertTitle,
            message: .launchResetAlertMessage,
            actions: [
                .init(type: .primary, title: .launchResetAlertButton) {
                    resetWindow?.isHidden = true
                    resetWindow?.removeFromSuperview()
                    resetWindow = nil
                }
            ])
        
        let stepController = StepViewController(viewModel: viewModel)
        
        resetWindow?.rootViewController = NavigationController(rootViewController: stepController)
        resetWindow?.makeKeyAndVisible()
    }
    
    private func updateConfiguration(completionHandler: (() -> Void)? = nil) {
        guard !isUpdatingConfiguration else { return }
        
        isUpdatingConfiguration = true
        
        Services.configManager.update { [unowned self] updateState in
            switch updateState {
            case .updateRequired(let versionInformation):
                showRequiredUpdate(with: versionInformation)
            case .updateFailed:
                showConfigUpdateFailed(retryHandler: { updateConfiguration(completionHandler: completionHandler) })
            case .noActionNeeded:
                completionHandler?()
            }
            
            isUpdatingConfiguration = false
        }
    }
    
    private func refreshCaseDataIfNeeded() {
        Services.caseManager.loadCaseData(userInitiated: false) { _, _ in }
    }
    
    private var privacyProtectionWindow: UIWindow?
    
    private func createWindow(level: UIWindow.Level = .alert + 1) -> UIWindow {
        var sceneWindow: UIWindow?
        
        if #available(iOS 13.0, *) {
            if let scene = window.windowScene {
                sceneWindow = UIWindow(windowScene: scene)
            }
        }
        
        let window = sceneWindow ?? UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = level
        
        return window
    }

    private func hideContent() {
        privacyProtectionWindow = createWindow()
        privacyProtectionWindow?.rootViewController = LaunchViewController(viewModel: .init())
        privacyProtectionWindow?.makeKeyAndVisible()
    }
    
    private func revealContent() {
        privacyProtectionWindow?.isHidden = true
        privacyProtectionWindow = nil
    }
    
    private var topViewController: UIViewController? {
        guard var topController = window.rootViewController else { return nil }

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
    
    /// - Tag: AppCoordinator.showRequiredUpdate
    private func showRequiredUpdate(with versionInformation: AppVersionInformation) {
        guard let topController = topViewController else { return }
        guard !(topController is AppUpdateViewController) else { return }
        
        let viewModel = AppUpdateViewModel(versionInformation: versionInformation)
        let updateController = AppUpdateViewController(viewModel: viewModel)
        updateController.delegate = self
        
        topController.present(updateController, animated: true)
    }
    
    private func showConfigUpdateFailed(retryHandler: @escaping () -> Void) {
        guard let topController = topViewController else { return }
        
        let alert = UIAlertController(title: .launchConfigAlertTitle, message: .launchConfigAlertMessage, preferredStyle: .alert)
        
        alert.addAction(.init(title: .tryAgain, style: .default) { _ in
            retryHandler()
        })
        
        topController.present(alert, animated: true)
    }

}

extension AppCoordinator: LaunchCoordinatorDelegate {
    
    func launchCoordinator(_ coordinator: LaunchCoordinator, needsConfigurationUpdate completion: @escaping () -> Void) {
        updateConfiguration(completionHandler: completion)
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
        resetData()
        removeChildCoordinator(coordinator)
        start()
    }
    
}
