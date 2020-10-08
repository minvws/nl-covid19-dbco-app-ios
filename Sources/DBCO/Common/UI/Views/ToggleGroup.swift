/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import UIKit

class ToggleGroup: UIStackView {
    
    init(_ buttons: ToggleButton ...) {
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 8
        
        buttons.forEach(addArrangedSubview)
        buttons.forEach { $0.addTarget(self, action: #selector(handleToggle), for: .valueChanged) }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleToggle(_ sender: ToggleButton) {
        guard sender.isSelected else {
            sender.isSelected = true
            return
        }
        
        arrangedSubviews.forEach {
            guard $0 !== sender else { return }
            ($0 as? ToggleButton)?.isSelected = !sender.isSelected
        }
    }
    
}
