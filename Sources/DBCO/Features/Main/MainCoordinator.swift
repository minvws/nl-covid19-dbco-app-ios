/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

final class MainCoordinator: Coordinator {
    private let window: UIWindow
    private let mainController: MainViewController
    
    var children = [Coordinator]()
    
    init(window: UIWindow) {
        self.window = window
        
        mainController = MainViewController()
        mainController.delegate = self
    }
    
    func start() {
        window.rootViewController = mainController
        window.makeKeyAndVisible()
    }
    
    func openHelp() {
        startChildCoordinator(HelpCoordinator(presenter: mainController, delegate: self))
    }
    
    func openContactSelection() {
        startChildCoordinator(SelectContactCoordinator(presenter: mainController, delegate: self))
    }

}

// MARK: - Coordinator delegates
extension MainCoordinator: HelpCoordinatorDelegate {
    
    func helpCoordinatorDidFinish(_ coordinator: HelpCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension MainCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: CNContact?) {
        removeChildCoordinator(coordinator)
        print(contact?.fullName)
    }
    
}

// MARK: - ViewController delegates
extension MainCoordinator: MainViewControllerDelegate {
    
    func mainViewControllerWantsHelp(_ controller: MainViewController) {
        openHelp()
    }
    
    func mainViewControllerRequestContact(_ contorller: MainViewController) {
        openContactSelection()
    }
    
}
