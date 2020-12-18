/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A collapsible container view for a with a header consisting of a title, a caption, a status indicator and a collapse indicator
/// - Tag: SectionView
class SectionView: UIView {
    
    /// Add your subviews to this view.
    let contentView = UIView()
    
    private(set) var isCollapsed: Bool = false
    
    /// Toggles the state of the status indicator view.
    /// if isCompleted is true a checkmark icon will be shown. If false, the index of the section will be shown.
    /// Currently supports up to index 3. To support more sections, just ensure the required images are available in the asset catalog (`"EditContact/Section\(index)"`).
    var isCompleted: Bool = false {
        didSet {
            icon.isHighlighted = isCompleted
        }
    }
    
    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var caption: String? {
        get { captionLabel.text }
        set { captionLabel.text = newValue }
    }
    
    var offset: CGFloat = 0 {
        didSet { updateHeaderForOffset() }
    }
    
    var isEnabled: Bool = true {
        didSet { updateEnabled() }
    }
    
    var showBottomSeparator: Bool = true {
        didSet { bottomSeparator.isHidden = !showBottomSeparator }
    }
    
    var index: Int {
        didSet { icon.image = UIImage(named: "EditContact/Section\(index)") }
    }
    
    init(title: String, caption: String, index: Int) {
        self.index = index
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        let outerStack = VStack(headerContainerView, contentContainerView)
            .embed(in: self)
        
        // Header
        let headerBackgroundView = UIView()
        headerBackgroundView.backgroundColor = .white
        // Make the background view extend above the header.
        // This helps obscure the content when animating from a scrolled state.
        headerBackgroundView.embed(in: headerContainerView, insets: .top(-100))
        
        outerStack.bringSubviewToFront(headerContainerView) // header should overlay content

        icon.image = UIImage(named: "EditContact/Section\(index)")
        icon.highlightedImage = UIImage(named: "EditContact/SectionCompleted")
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.tintColor = Theme.colors.primary
        
        collapseIndicator.image = UIImage(named: "EditContact/SectionCollapse")
        collapseIndicator.setContentHuggingPriority(.required, for: .horizontal)
        
        titleLabel.text = title
        captionLabel.text = caption
        
        HStack(spacing: 16, icon, VStack(spacing: 2, titleLabel, captionLabel), collapseIndicator)
            .distribution(.fill)
            .alignment(.center)
            .embed(in: headerContainerView.readableWidth, insets: .topBottom(14))
        
        SeparatorView()
            .snap(to: .bottom, of: headerContainerView.readableIdentation)
        
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleToggleButton), for: .touchUpInside)
        button.embed(in: headerContainerView)
        button.accessibilityTraits = [.header, .button]
        button.accessibilityLabel = title
        button.accessibilityHint = caption
        
        // Content
        contentContainerView.clipsToBounds = true
        contentView
            .snap(to: .bottom, of: contentContainerView, insets: .bottom(24))

        bottomSeparator
            .snap(to: .bottom, of: contentContainerView.readableIdentation)
        
        // A low priority top constraint that will break when collapsing, so content will seem to move upwards while animating, instead of getting squished
        let contentTopConstraint = contentView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 24)
        contentTopConstraint.priority = UILayoutPriority(rawValue: 100)
        contentTopConstraint.isActive = true
        
        // Set default state to expanded
        expand(animated: false)
    }
    
    @objc private func handleToggleButton() {
        toggle(animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggle(animated: Bool) {
        if isCollapsed {
            expand(animated: animated)
        } else {
            collapse(animated: animated)
        }
    }
    
    func expand(animated: Bool) {
        guard isEnabled else { return }
        
        collapseIndicator.transform = CGAffineTransform(rotationAngle: .pi - 0.000001) // set that rotation to something very close to, but not quite 180 degrees so animating back to 0 reverses the rotation
        
        func applyAnimatedState() {
            contentView.alpha = 1
            contentContainerView.isHidden = false
            isCollapsed = false
            collapseIndicator.transform = .identity
        }
        
        if animated {
            UIView.animate(withDuration: 0.35) {
                applyAnimatedState()
            }
        } else {
            applyAnimatedState()
        }
    }
    
    func collapse(animated: Bool) {
        func applyAnimatedState() {
            contentView.alpha = 0
            contentView.endEditing(true)
            contentContainerView.isHidden = true
            isCollapsed = true
            collapseIndicator.transform = CGAffineTransform(rotationAngle: .pi)
        }
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                applyAnimatedState()
            }
        } else {
            applyAnimatedState()
        }
    }
    
    /// Makes the header stick to the top of the screen
    ///
    /// - Tag: SectionView.updateForOffset
    private func updateHeaderForOffset() {
        headerContainerView.transform = .identity
        
        guard !isCollapsed else { return }
        guard traitCollection.verticalSizeClass == .regular else { return }
        
        let clampedOffset = min(max(offset, 0), frame.height - headerContainerView.frame.height)
        
        headerContainerView.transform = CGAffineTransform(translationX: 0, y: clampedOffset)
    }
    
    private func updateEnabled() {
        isUserInteractionEnabled = isEnabled
        
        if isEnabled {
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = isCompleted
            
            titleLabel.textColor = .black
        } else {
            collapse(animated: false)
            icon.tintColor = Theme.colors.captionGray
            icon.isHighlighted = false
            
            titleLabel.textColor = Theme.colors.captionGray
        }
    }
    
    private let contentContainerView = UIView()
    private let headerContainerView = UIView()
    private let icon = UIImageView()
    private let collapseIndicator = UIImageView()
    private let titleLabel = Label(bodyBold: "")
    private let captionLabel = Label(subhead: "", textColor: Theme.colors.captionGray)
    private let bottomSeparator = SeparatorView()
}
