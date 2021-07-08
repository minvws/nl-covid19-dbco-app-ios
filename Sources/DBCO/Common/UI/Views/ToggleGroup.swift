/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// UIStackView subclass managing an array of [ToggleButton](x-source-tag://ToggleButton)s.
/// Only one ToggleButton can be highlighted at any one time.
/// When one of the managed buttons is toggled it will call the [selectionHandler](x-source-tag://ToggleGroup.didSelect)
///
/// # See also:
/// [didSelect(handler:)](x-source-tag://ToggleGroup.didSelect),
/// [DateToggleButton](x-source-tag://DateToggleButton),
/// [ToggleButton](x-source-tag://ToggleButton)
///
/// - Tag: ToggleGroup
class ToggleGroup: UIStackView {
    
    convenience init(label: String? = nil, _ buttons: ToggleButton ...) {
        self.init(label: label, buttons)
    }
    
    init(label: String? = nil, _ buttons: [ToggleButton]) {
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 8
        
        self.label.text = label
        addArrangedSubview(self.label)
        
        buttons.forEach(addArrangedSubview)
        buttons.forEach { $0.addTarget(self, action: #selector(handleToggle), for: .valueChanged) }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isEnabled: Bool = true {
        didSet {
            arrangedSubviews.forEach {
                if let button = $0 as? ToggleButton {
                    button.isEnabled = isEnabled
                    button.isHidden = button.isSelected ? false : !isEnabled
                }
            }
        }
    }
    
    var isEmphasized: Bool {
        return true
    }
    
    /// - Tag: ToggleGroup.didSelect
    @discardableResult
    func didSelect(handler: @escaping (Int) -> Void) -> Self {
        selectionHandler = handler
        return self
    }
    
    // MARK: - Private
    private var selectionHandler: ((Int) -> Void)?
    
    @objc private func handleToggle(_ sender: ToggleButton) {
        guard sender.isSelected else {
            sender.isSelected = true
            return
        }
        
        arrangedSubviews.forEach {
            guard $0 !== sender else { return }
            ($0 as? ToggleButton)?.isSelected = !sender.isSelected
        }
        
        if let index = arrangedSubviews.firstIndex(where: { $0 === sender }) {
            selectionHandler?(index - 1) // label is index 0
        }
    }
    
    private(set) var label = UILabel(bodyBold: nil)
    
}
