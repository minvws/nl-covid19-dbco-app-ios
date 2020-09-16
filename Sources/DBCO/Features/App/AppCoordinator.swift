/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol Coordinator: class {
    var children: [Coordinator] { get set }
    
    func start()
}

extension Coordinator {
    
    func startChildCoordinator(_ coordinator: Coordinator) {
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func addChildCoordinator(_ coordinator: Coordinator) {
        if !children.contains(where: { $0 === coordinator }) {
            children.append(coordinator)
        }
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        if let index = children.firstIndex(where: { $0 === coordinator }) {
            children.remove(at: index)
        }
    }
    
}

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    
    var children = [Coordinator]()
    
    init(scene: UIWindowScene) {
        window = UIWindow(windowScene: scene)
    }
    
    func start() {
        startChildCoordinator(MainCoordinator(window: window))
    }

}
