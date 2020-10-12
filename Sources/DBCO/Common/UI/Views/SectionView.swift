/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import UIKit

class SectionView: UIView {
    
    let contentView = UIView()
    
    private(set) var isCollapsed: Bool = false
    
    var isCompleted: Bool = false {
        didSet {
            icon.isHighlighted = isCompleted
        }
    }
    
    init(title: String, caption: String, index: Int) {
        super.init(frame: .zero)
        
        VStack(headerContainerView, contentContainerView)
            .embed(in: self)
        
        // Header
        headerContainerView.backgroundColor = .white
        headerContainerView.layer.zPosition = 1
        
        icon.image = UIImage(named: "EditContact/Section\(index)")
        icon.highlightedImage = UIImage(named: "EditContact/SectionCompleted")
        icon.setContentHuggingPriority(.required, for: .horizontal)
        
        collapseIndicator.image =  UIImage(named: "EditContact/SectionCollapse")
        collapseIndicator.setContentHuggingPriority(.required, for: .horizontal)
        
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = Theme.fonts.bodyBold
        titleLabel.text = title
        
        let captionLabel = UILabel(frame: .zero)
        captionLabel.font = Theme.fonts.subhead
        captionLabel.textColor = Theme.colors.captionGray
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

        SeparatorView()
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
    
    private let contentContainerView = UIView()
    private let headerContainerView = UIView()
    private let icon = UIImageView()
    private let collapseIndicator = UIImageView()
}
