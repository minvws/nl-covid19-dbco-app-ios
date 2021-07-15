/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A collapsible container view for a with a header consisting of a title, a caption, a status indicator and a collapse indicator
///
/// # See also
/// [SectionedScrollView](x-source-tag://SectionedScrollView)
///
/// - Tag: SectionView
class SectionView: UIView {
    
    /// Add your subviews to this view.
    let contentView = UIView()
    
    private(set) var isCollapsed: Bool = false {
        didSet {
            updateHeaderAccessibilityLabel()
        }
    }
    
    /// Toggles the state of the status indicator view.
    /// if isCompleted is true a checkmark icon will be shown. If false, the index of the section will be shown.
    /// Currently supports up to index 3. To support more sections, just ensure the required images are available in the asset catalog (`"EditContact/Section\(index)"`).
    var isCompleted: Bool = false {
        didSet {
            icon.isHighlighted = isCompleted
            updateHeaderAccessibilityLabel()
            
            if isCompleted {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: String.contactSectionCompleted(index: index)
                )
            }
        }
    }
    
    var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }
    
    var caption: String {
        get { captionLabel.text ?? "" }
        set { captionLabel.text = newValue }
    }
    
    var disabledCaption: String? {
        get { disabledCaptionLabel.text }
        set { disabledCaptionLabel.text = newValue }
    }
    
    var offset: CGFloat = 0 {
        didSet { updateHeaderForOffset() }
    }
    
    var isEnabled: Bool = true {
        didSet {
            updateEnabled()
            updateHeaderAccessibilityLabel()
        }
    }
    
    var showBottomSeparator: Bool = true {
        didSet { bottomSeparator.isHidden = !showBottomSeparator }
    }
    
    var index: Int {
        didSet {
            icon.image = UIImage(named: "EditContact/Section\(index)")
        }
    }
    
    init(title: String, caption: String, disabledCaption: String? = nil, index: Int) {
        self.index = index
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        let outerStack = VStack(headerContainerView, contentContainerView)
            .embed(in: self)
        
        outerStack.bringSubviewToFront(headerContainerView)
        
        self.title = title
        self.caption = caption
        self.disabledCaption = disabledCaption
        
        disabledCaptionLabel.isHidden = true
        
        setupHeaderView()
        setupContentView()
        
        // Set default state to expanded
        expand(animated: false)
    }
    
    private func setupHeaderView() {
        headerContainerView.isAccessibilityElement = true
        headerContainerView.shouldGroupAccessibilityChildren = true
        headerContainerView.accessibilityTraits = [.header, .button]
        headerContainerView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleToggleButton))
        )
        updateHeaderAccessibilityLabel()
        
        let headerBackgroundView = UIView()
        headerBackgroundView.backgroundColor = .white
        // Make the background view extend above the header.
        // This helps obscure the content when animating from a scrolled state.
        headerBackgroundView.embed(in: headerContainerView, insets: .top(-100))
        
        icon.image = UIImage(named: "EditContact/Section\(index)")
        icon.highlightedImage = UIImage(named: "EditContact/SectionCompleted")
        
        HStack(spacing: 16, icon, VStack(spacing: 2, titleLabel, captionLabel, disabledCaptionLabel), collapseIndicator)
            .distribution(.fill)
            .alignment(.center)
            .embed(in: headerContainerView.readableWidth, insets: .topBottom(14))
        
        SeparatorView()
            .snap(to: .bottom, of: headerContainerView.readableIdentation)
    }
    
    private func setupContentView() {
        contentContainerView.clipsToBounds = true
        contentView
            .snap(to: .bottom, of: contentContainerView, insets: .bottom(24))

        bottomSeparator
            .snap(to: .bottom, of: contentContainerView.readableIdentation)
        
        // A low priority top constraint that will break when collapsing, so content will seem to move upwards while animating, instead of getting squished
        let contentTopConstraint = contentView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 24)
        contentTopConstraint.priority = UILayoutPriority(rawValue: 100)
        contentTopConstraint.isActive = true
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
            captionLabel.isHidden = false
            disabledCaptionLabel.isHidden = true
        } else {
            collapse(animated: false)
            icon.tintColor = Theme.colors.captionGray
            icon.isHighlighted = false
            
            titleLabel.textColor = Theme.colors.captionGray
            captionLabel.isHidden = true
            disabledCaptionLabel.isHidden = false
        }
        
        captionLabel.isHidden = shouldShowDisabledCaption
        disabledCaptionLabel.isHidden = !shouldShowDisabledCaption
    }
    
    private var shouldShowDisabledCaption: Bool {
        return !isEnabled && !(disabledCaption?.isEmpty ?? true)
    }
    
    private func updateHeaderAccessibilityLabel() {
        headerContainerView.accessibilityLabel = .contactSectionLabel(
            index: index,
            title: title,
            caption: shouldShowDisabledCaption ? disabledCaption! : caption,
            isCollapsed: isCollapsed,
            isCompleted: isCompleted,
            isEnabled: isEnabled
        )
    }
    
    private let contentContainerView = UIView()
    private let headerContainerView = UIView()
    private let icon = UIImageView().asIcon()
    private let collapseIndicator = UIImageView(imageName: "EditContact/SectionCollapse").asIcon()
    private let titleLabel = UILabel(bodyBold: "")
    private let captionLabel = UILabel(subhead: "", textColor: Theme.colors.captionGray)
    private let disabledCaptionLabel = UILabel(subhead: "", textColor: Theme.colors.captionGray)
    private let bottomSeparator = SeparatorView()
}
