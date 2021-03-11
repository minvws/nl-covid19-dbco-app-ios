/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A styled UINavigationController subclass.
/// Conforms to [DismissActionable](x-source-tag://DismissActionable)
class NavigationController: UINavigationController, DismissActionable {
    var onDismissed: ((NavigationController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.barTintColor = Theme.colors.navigationControllerBackground
        navigationBar.tintColor = Theme.colors.primary
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed {
            onDismissed?(self)
        }
    }
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        // Unset any onPopped callbacks on controllers that are removed
        self.viewControllers
            .filter { !viewControllers.contains($0) }
            .forEach { ($0 as? ViewController)?.onPopped = nil }
        
        super.setViewControllers(viewControllers, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
