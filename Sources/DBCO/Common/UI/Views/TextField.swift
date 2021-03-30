/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled subclass of UITextField.
/// Optionally shows a label above the textfield.
class TextField: UITextField {
    var isEmphasized: Bool = false
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    init(label: String?, text: String? = nil) {
        super.init(frame: .zero)
        setup()
        
        placeholder = label
        self.text = text
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override var isEnabled: Bool {
        didSet {
            textColor = isEnabled ? .black : .init(white: 0, alpha: 0.5)
        }
    }
    
    private func setup() {
        backgroundView.backgroundColor = Theme.colors.tertiary
        backgroundView.layer.cornerRadius = 8
        backgroundView.isUserInteractionEnabled = false
        
        font = Theme.fonts.body
        
        addSubview(label)
        addSubview(warningLabel)
        addSubview(warningIcon)
        addSubview(backgroundView)
        addSubview(errorLabel)
        addSubview(errorIcon)
        
        warningLabel.adjustsFontSizeToFitWidth = true
        
        hideWarning()
        hideError()
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func borderRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        // The supplied bounds might be something completely different from the views bounds.
        // So, we need to inset the supplied bounds as if the field would be placed within those bounds.
        // For this, we need to treat the textfield as expanding or collapsing vertically
        return bounds.inset(by: .top(backgroundView.frame.minY) +
                                .bottom(self.bounds.height - backgroundView.frame.maxY) +
                                .leftRight(12))
    }
    
    override var intrinsicContentSize: CGSize {
        let labelHeight = label.intrinsicContentSize.height
        let warningHeight = warningLabel.intrinsicContentSize.height
        let errorHeight = errorLabel.intrinsicContentSize.height
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        var height = backgroundHeight
        
        if label.text?.isEmpty == false {
            height += labelHeight + Constants.spacing
        }
        
        if warningLabel.text?.isEmpty == false, warningLabel.isHidden == false {
            height += warningHeight + Constants.warningSpacing
        }
        
        if errorLabel.text?.isEmpty == false, errorLabel.isHidden == false {
            height += errorHeight + Constants.errorSpacing
        }
        
        return CGSize(width: 100, height: height)
    }
    
    override func layoutSubviews() {
        let iconWidth: CGFloat = 16
        let iconSpacing: CGFloat = 4
        let warningOffset = iconWidth + iconSpacing
        
        errorLabel.preferredMaxLayoutWidth = bounds.width - warningOffset
        
        let labelHeight = label.intrinsicContentSize.height
        let warningHeight = warningLabel.intrinsicContentSize.height
        let errorHeight = errorLabel.intrinsicContentSize.height
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: labelHeight)
        
        warningLabel.frame = CGRect(x: warningOffset,
                                    y: labelHeight + Constants.warningSpacing,
                                    width: bounds.width - warningOffset,
                                    height: warningHeight)
        warningIcon.frame = CGRect(x: 0, y: labelHeight + Constants.warningSpacing, width: iconWidth, height: warningHeight)
        
        var backgroundOffset = bounds.height - backgroundHeight
        
        if errorLabel.text?.isEmpty == false, errorLabel.isHidden == false {
            backgroundOffset -= errorHeight + Constants.errorSpacing
        }
        
        backgroundView.frame = CGRect(x: 0, y: backgroundOffset, width: bounds.width, height: backgroundHeight)
        
        errorLabel.frame = CGRect(x: warningOffset,
                                    y: bounds.height - errorHeight,
                                    width: bounds.width - warningOffset,
                                    height: errorHeight)
        errorIcon.frame = CGRect(x: 0, y: errorLabel.frame.minY, width: iconWidth, height: errorHeight)
        
        // Call super last because the _rect(forBounts: ..) calculations depend on backgroundView.frame
        super.layoutSubviews()
    }
    
    func showWarning(_ warning: String) {
        warningLabel.text = warning
        warningLabel.isHidden = false
        warningIcon.isHidden = false
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    func hideWarning() {
        warningLabel.isHidden = true
        warningIcon.isHidden = true
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    func showError(_ error: String) {
        errorLabel.text = error
        errorLabel.isHidden = false
        errorIcon.isHidden = false
        
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = Theme.colors.warning.cgColor
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    func hideError() {
        errorLabel.isHidden = true
        errorIcon.isHidden = true
        
        backgroundView.layer.borderWidth = 0
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Private
    
    private struct Constants {
        static let spacing: CGFloat = 8
        static let warningSpacing: CGFloat = 2
        static let backgroundBaseHeight: CGFloat = 26
        static let errorSpacing: CGFloat = 2
    }
    
    private var baseFieldHeight: CGFloat {
        return ceil(font!.lineHeight + 1)
    }
    
    private(set) var label = UILabel(subhead: nil)
    private(set) var backgroundView = UIView()
    
    private(set) var warningLabel = UILabel(subhead: nil, textColor: Theme.colors.primary)
    private(set) var warningIcon = UIImageView(imageName: "Validation/Warning").asIcon(color: Theme.colors.primary)
    
    private(set) var errorLabel = UILabel(subhead: nil, textColor: Theme.colors.warning).multiline()
    private(set) var errorIcon = UIImageView(imageName: "Validation/Invalid").asIcon(color: Theme.colors.warning)
    
}
