//
//  SelectableButton.swift
//  DBCO
//
//  Created by Thom Hoekstra on 19/05/2021.
//  Copyright © 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport. All rights reserved.
//

import UIKit

class SelectableButton: UIButton {
    
    override var isSelected: Bool {
        didSet { applyState() }
    }
    
    override var isEnabled: Bool {
        didSet { applyState() }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get { return UISwitch().accessibilityTraits }
        set { super.accessibilityTraits = newValue }
    }
    
    override var accessibilityValue: String? {
        get { return isSelected ? "1" : "0" }
        set { super.accessibilityValue = newValue }
    }
    
    var useHapticFeedback = true
    
    required init(title: String = "", selected: Bool = false, iconAlignment: ContentMode = .top) {
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
        icon.contentMode = iconAlignment
        let insets: UIEdgeInsets = iconAlignment == .center ? .left(16) : .left(16) + .topBottom(16)
        icon.snap(to: .left, of: self, insets: insets)
        
        isSelected = selected
        
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func setup() {
        clipsToBounds = true
        contentEdgeInsets = .topBottom(17) + .left(52) + .right(16)
        
        layer.cornerRadius = 8
        
        titleLabel?.font = Theme.fonts.body
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        
        tintColor = .white
        backgroundColor = Theme.colors.tertiary
        setTitleColor(UIColor(white: 0.235, alpha: 0.85), for: .normal)
        contentHorizontalAlignment = .left
        
        applyState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.preferredMaxLayoutWidth = bounds.width - contentEdgeInsets.left - contentEdgeInsets.right
    }
    
    override var intrinsicContentSize: CGSize {
        var base = titleLabel?.intrinsicContentSize ?? .zero
        base.height += contentEdgeInsets.top + contentEdgeInsets.bottom
        base.width += contentEdgeInsets.left + contentEdgeInsets.right
        return base
    }
    
    @discardableResult
    func valueChanged(_ target: Any?, action: Selector) -> Self {
        super.addTarget(target, action: action, for: .valueChanged)
        return self
    }
    
    private func applyState() {
        switch (isSelected, isEnabled) {
        case (true, true):
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = true
        case (true, false):
            icon.tintColor = Theme.colors.disabledIcon
            icon.isHighlighted = true
        default:
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
