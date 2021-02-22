/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIWindow {
    
    func transition(to controller: UIViewController, with options: UIView.AnimationOptions = []) {
        let snapshotView = self.snapshotView(afterScreenUpdates: true)!
        rootViewController = controller
        controller.view.addSubview(snapshotView)
        
        UIView.transition(with: self, duration: 0.5, options: options) {
            snapshotView.removeFromSuperview()
        }
    }
}
