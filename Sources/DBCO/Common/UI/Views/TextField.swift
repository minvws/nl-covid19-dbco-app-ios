/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled subclass of UITextField.
/// - Tag: TextField
class TextField: UITextField {
    
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
    
    func setBorder(width: CGFloat, color: UIColor? = nil) {
        backgroundView.layer.borderWidth = width
        backgroundView.layer.borderColor = color?.cgColor
    }
    
    private func setup() {
        backgroundView.backgroundColor = Theme.colors.tertiary
        backgroundView.layer.cornerRadius = 8
        backgroundView.isUserInteractionEnabled = false
        
        font = Theme.fonts.body
        addSubview(backgroundView)
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
        let height = baseFieldHeight + Constants.backgroundBaseHeight
        return CGSize(width: 200, height: height)
    }
    
    override func layoutSubviews() {
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        backgroundView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: backgroundHeight)
        
        // Call super last because the _rect(forBounds: ..) calculations depend on backgroundView.frame
        super.layoutSubviews()
    }
    
    // MARK: - Private
    
    private struct Constants {
        static let backgroundBaseHeight: CGFloat = 26
    }
    
    private var baseFieldHeight: CGFloat {
        return ceil(font!.lineHeight + 1)
    }
    
    private(set) var backgroundView = UIView()
    
}
