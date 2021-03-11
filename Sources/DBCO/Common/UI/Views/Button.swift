/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A styled UIButton subclass
class Button: UIButton {

    enum ButtonType {
        case primary
        case secondary
        case tertiary
        case warning
        case info
    }

    var style = ButtonType.primary {
        didSet {
            updateButtonType()
        }
    }

    var rounded = false {
        didSet {
            updateRoundedCorners()
        }
    }

    var title = "" {
        didSet {
            self.setTitle(title, for: .normal)
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateButtonType()
        }
    }

    var useHapticFeedback = true

    // MARK: - Init

    required init(title: String = "", style: ButtonType = .primary) {
        super.init(frame: .zero)

        self.setTitle(title, for: .normal)
        self.title = title
        
        self.titleLabel?.font = Theme.fonts.headline
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.lineBreakMode = .byWordWrapping
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchDragExit)
        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchCancel)
        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchUpInside)
        self.addTarget(self, action: #selector(self.touchDownAnimation), for: .touchDown)
        
        self.style = style

        updateButtonType()
        
        // Bold font can cause the button to be marked as heading, this should never be the case.
        accessibilityTraits.remove(.header)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    func touchUpInside(_ target: Any?, action: Selector) -> Self {
        super.addTarget(target, action: action, for: .touchUpInside)
        return self
    }
    
    func flashTitle(_ title: String, duration: TimeInterval = 2) {
        guard !isFlashingTitle else { return }
        
        let currentTitle = self.title
        self.title = title
        
        isFlashingTitle = true
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.title = currentTitle
            self.isFlashingTitle = false
        }
    }

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRoundedCorners()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
    }
    
    // Takes the intrinsic size of the title label into account for larger font sizes
    override var intrinsicContentSize: CGSize {
        get {
            let size = titleLabel?.intrinsicContentSize ?? CGSize.zero
            let insets = contentEdgeInsets
            
            return CGSize(
                width: size.width + insets.left + insets.right,
                height: size.height + insets.top + insets.bottom
            )
        }
    }

    // MARK: - Private

    private func updateButtonType() {
        switch style {
        case .primary:
            if isEnabled {
                backgroundColor = Theme.colors.primary
                setTitleColor(.white, for: .normal)
            } else {
                backgroundColor = Theme.colors.tertiary
                setTitleColor(.gray, for: .normal)
            }
        case .secondary:
            backgroundColor = Theme.colors.tertiary
            setTitleColor(Theme.colors.primary, for: .normal)
        case .tertiary:
            backgroundColor = Theme.colors.tertiary
            setTitleColor(.black, for: .normal)
        case .warning:
            backgroundColor = Theme.colors.warning
            setTitleColor(.white, for: .normal)
        case .info:
            backgroundColor = .clear
            setTitleColor(Theme.colors.primary, for: .normal)
        }
        
        contentEdgeInsets = .topBottom(13.5) + .leftRight(20)
        tintColor = .white
    }

    private func updateRoundedCorners() {
        if rounded {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
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
    
    private var isFlashingTitle: Bool = false
}
