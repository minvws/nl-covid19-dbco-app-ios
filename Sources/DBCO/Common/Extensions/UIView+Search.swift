//
//  UIView+Search.swift
//  DBCO
//
//  Created by Jan Jaap de Groot on 18/02/2021.
//  Copyright © 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport. All rights reserved.
//

import UIKit

extension UIView {

    /// Recursive method to determine all subviews
    func allSubviews() -> [UIView] {
        return subviews + subviews.flatMap { $0.allSubviews() }
    }
    
    /// Finds the first subview with the provided accessibility traits
    func find(traits: UIAccessibilityTraits) -> UIView? {
        return allSubviews().filter { (view) -> Bool in
            view.accessibilityTraits.contains(accessibilityTraits)
        }.first
    }
}
