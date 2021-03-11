/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

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
        
        Services.configManager.update { [unowned self] updateState, _ in
            switch updateState {
            case .updateRequired(let versionInformation):
                self.delegate?.launchCoordinator(self, needsRequiredUpdate: versionInformation)
            case .noActionNeeded:
                self.delegate?.launchCoordinatorDidFinish(self)
            }
        }
    }
}
