/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DismissActionable {
    associatedtype Item
    
    var onDismissed: ((Item) -> Void)? { get set }
}

protocol PopActionable {
    associatedtype Item
    
    var onPopped: ((Item) -> Void)? { get set }
}

class ViewController: UIViewController, DismissActionable, PopActionable {
    var onDismissed: ((ViewController) -> Void)?
    var onPopped: ((ViewController) -> Void)?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed || navigationController?.isBeingDismissed == true || tabBarController?.isBeingDismissed == true {
            onDismissed?(self)
        } else if isMovingFromParent {
            onPopped?(self)
        }
    }
}

class NavigationController: UINavigationController, DismissActionable {
    var onDismissed: ((NavigationController) -> Void)?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed {
            onDismissed?(self)
        }
    }
}
