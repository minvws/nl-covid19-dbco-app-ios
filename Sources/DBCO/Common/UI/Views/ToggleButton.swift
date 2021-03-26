/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled UIButton subclass that will toggle between highlighted states when tapped.
/// When toggled it will send out a `.valueChanged` action to interested targets.
/// 
/// # See also:
/// [DateToggleButton](x-source-tag://DateToggleButton),
/// [ToggleGroup](x-source-tag://ToggleGroup)
///
/// - Tag: ToggleButton
class ToggleButton: UIButton {
    
    override var isSelected: Bool {
        didSet { applyState() }
    }
    
    override var isEnabled: Bool {
        didSet { applyState() }
    }
    
    var useHapticFeedback = true
    
    required init(title: String = "", selected: Bool = false) {
        icon = UIImageView(image: UIImage(named: "Toggle/Normal"),
                           highlightedImage: UIImage(named: "Toggle/Selected"))
        
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)

        addTarget(self, action: #selector(touchUpAnimation), for: .touchDragExit)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchCancel)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchUpInside)
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        addTarget(self, action: #selector(touchDownAnimation), for: .touchDown)
        
        icon.tintColor = Theme.colors.primary
        icon.contentMode = .center
        icon.snap(to: .right, of: self, insets: .right(16))
        
        isSelected = selected
        
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    fileprivate func setup() {
        clipsToBounds = true
        contentEdgeInsets = .topBottom(25.5) + .left(16) + .right(32)
        
        layer.cornerRadius = 8
        
        titleLabel?.font = Theme.fonts.body
        titleLabel?.numberOfLines = 2
        
        tintColor = .white
        backgroundColor = Theme.colors.tertiary
        setTitleColor(.black, for: .normal)
        setTitleColor(UIColor.black.withAlphaComponent(0.5), for: [.selected, .disabled])
        contentHorizontalAlignment = .left
        
        applyState()
    }
    
    private func applyState() {
        switch (isSelected, isEnabled) {
        case (true, true):
            layer.borderWidth = 2
            layer.borderColor = Theme.colors.primary.cgColor
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = true
        case (true, false):
            layer.borderWidth = 2
            layer.borderColor = Theme.colors.disabledBorder.cgColor
            icon.tintColor = Theme.colors.disabledIcon
            icon.isHighlighted = true
            
        default:
            layer.borderWidth = 0
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = false
        }
    }
    
    @objc private func toggle() {
        isSelected.toggle()
        sendActions(for: .valueChanged)
    }
    
    @objc private func touchDownAnimation() {
        if useHapticFeedback { Haptic.light() }

        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        })
    }

    @objc private func touchUpAnimation() {
        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform.identity
        })
    }
    
    fileprivate let icon: UIImageView
}
