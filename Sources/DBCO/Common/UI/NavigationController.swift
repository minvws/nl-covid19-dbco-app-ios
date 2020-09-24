/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class NavigationController: UINavigationController, DismissActionable {
    var onDismissed: ((NavigationController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.barTintColor = Theme.colors.navigationControllerBackground
        navigationBar.tintColor = Theme.colors.primary
        
        setLeftMarginIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed {
            onDismissed?(self)
        }
    }
    
    private func setLeftMarginIfNeeded() {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }
        
        let leftMargin = view.readableContentGuide.layoutFrame.minX
        navigationBar.layoutMargins.left = leftMargin
        navigationBar.layoutMarginsDidChange()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.setLeftMarginIfNeeded()
        }, completion: nil)
    }
}
