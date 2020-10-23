/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// The root coordinator of the app. Will present the onboarding if needed and moves to the task overview.
final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let taskManager = TaskManager()
    
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
        let startCoordinator = OnboardingCoordinator(window: window)
        startCoordinator.delegate = self
        startChildCoordinator(startCoordinator)
    }

}

extension AppCoordinator: OnboardingCoordinatorDelegate {
    
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator) {
        removeChildCoordinator(coordinator)
        
        startChildCoordinator(TaskOverviewCoordinator(window: window))
    }
    
}
