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
            backgroundView.backgroundColor = isEnabled ? Theme.colors.tertiary : Theme.colors.disabledBorder
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
        
        warningLabel.adjustsFontSizeToFitWidth = true
        hideWarning()
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
        if isEditing {
            return bounds.inset(by: .bottom(self.bounds.height - backgroundView.frame.height))
        } else {
            return bounds.inset(by: .leftRight(12) + .top(self.bounds.height - backgroundView.frame.height))
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let labelHeight = label.intrinsicContentSize.height
        let warningHeight = warningLabel.intrinsicContentSize.height
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        var height = backgroundHeight
        
        if label.text?.isEmpty == false {
            height += labelHeight + Constants.spacing
        }
        
        if warningLabel.text?.isEmpty == false, warningLabel.isHidden == false {
            height += warningHeight + Constants.warningSpacing
        }
        
        return CGSize(width: 100, height: height)
    }
    
    override func layoutSubviews() {
        let labelHeight = label.intrinsicContentSize.height
        let warningHeight = warningLabel.intrinsicContentSize.height
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: labelHeight)
        warningLabel.frame = CGRect(x: 20, y: labelHeight + Constants.warningSpacing, width: bounds.width - 20, height: warningHeight)
        warningIcon.frame = CGRect(x: 0, y: labelHeight + Constants.warningSpacing, width: 16, height: warningHeight)
        backgroundView.frame = CGRect(x: 0, y: bounds.height - backgroundHeight, width: bounds.width, height: backgroundHeight)
        
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
    
    // MARK: - Private
    
    private struct Constants {
        static let spacing: CGFloat = 8
        static let warningSpacing: CGFloat = 2
        static let backgroundBaseHeight: CGFloat = 26
    }
    
    private var baseFieldHeight: CGFloat {
        return ceil(font!.lineHeight + 1)
    }
    
    private(set) var label = Label(subhead: nil)
    private(set) var warningLabel = Label(subhead: nil, textColor: Theme.colors.primary)
    private(set) var warningIcon = ImageView(imageName: "Validation/Warning").asIcon(color: Theme.colors.primary)
    private(set) var backgroundView = UIView()
    
}
