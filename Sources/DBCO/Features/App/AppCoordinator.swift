/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class Coordinator: NSObject {
    private(set) var children = [Coordinator]()
    
    func start() {
        preconditionFailure("Override start() in your subclass")
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

extension Coordinator {
    func startChildCoordinator(_ coordinator: Coordinator) {
        addChildCoordinator(coordinator)
        coordinator.start()
    }
}

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    
    
    init(scene: UIWindowScene) {
        window = UIWindow(windowScene: scene)
    }
    
    override func start() {
        startChildCoordinator(TaskOverviewCoordinator(window: window))
    }

}
