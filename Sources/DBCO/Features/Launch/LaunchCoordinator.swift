/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import IOSSecuritySuite
import LocalAuthentication

protocol LaunchCoordinatorDelegate: class {
    func launchCoordinator(_ coordinator: LaunchCoordinator, needsRequiredUpdate version: AppVersionInformation)
    func launchCoordinatorDidFinish(_ coordinator: LaunchCoordinator)
}

final class LaunchCoordinator: Coordinator {
    private let window: UIWindow
    
    weak var delegate: LaunchCoordinatorDelegate?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    override func start() {
        LogHandler.setup()
        
        window.tintColor = Theme.colors.primary
        
        window.rootViewController = LaunchViewController(viewModel: .init())
        window.makeKeyAndVisible()
        
        verifySystemIntegrity()
    }
    
    private func verifySystemIntegrity() {
        if IOSSecuritySuite.amIJailbroken() {
            showJailbreakAlert { self.verifySystemSecurity() }
        } else {
            verifySystemSecurity()
        }
    }
        
    private func verifySystemSecurity() {
        let isPasscodeEnabled = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        if !isPasscodeEnabled {
            showNoPasscodeAlert { self.fetchConfigurationAndContinue() }
        } else {
            fetchConfigurationAndContinue()
        }
    }
    
    private func fetchConfigurationAndContinue() {
        Services.configManager.update { [unowned self] updateState, _ in
            switch updateState {
            case .updateRequired(let versionInformation):
                self.delegate?.launchCoordinator(self, needsRequiredUpdate: versionInformation)
            case .noActionNeeded:
                self.delegate?.launchCoordinatorDidFinish(self)
            }
        }
    }
    
    // MARK: - Alerts
    
    private func showJailbreakAlert(completion: @escaping () -> Void) {
        guard let launchController = window.rootViewController else { return completion() }
        
        let alert = UIAlertController(title: .launchJailbreakAlertTitle,
                                      message: .launchJailbreakAlertMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .launchJailbreakAlertReadMoreButton, style: .default) { _ in
            UIApplication.shared.open(URL(string: .launchJailbreakAlertReadMoreURL)!)
            completion()
        })
        
        launchController.present(alert, animated: true, completion: nil)
    }
    
    private func showNoPasscodeAlert(completion: @escaping () -> Void) {
        guard let launchController = window.rootViewController else { return completion() }
        
        let alert = UIAlertController(title: .launchNoPasscodeAlertTitle,
                                      message: .launchNoPasscodeAlertMessage,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .launchNoPasscodeAlertNotNowButton, style: .default) { _ in
            completion()
        })
        
        alert.addAction(UIAlertAction(title: .launchNoPasscodeAlertToSettingsButton, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            completion()
        })
        
        launchController.present(alert, animated: true, completion: nil)
    }
}
