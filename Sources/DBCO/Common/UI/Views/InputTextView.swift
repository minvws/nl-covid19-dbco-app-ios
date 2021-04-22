/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A styled wrapped for UITextView that binds to an object's field conforming to [Editable](x-source-tag://Editable) and automatically updates its value.
/// - Tag: InputTextView
class InputTextView<Object: AnyObject, Field: Editable>: UIView {
    private weak var object: Object?
    
    private let textView = TextView()
    
    var isEnabled: Bool {
        get { textView.isEditable }
        
        set {
            textView.isEditable = newValue
            textView.textColor = newValue ? .black : .init(white: 0, alpha: 0.5)
        }
    }
    
    var isEmphasized: Bool {
        didSet {
            label.font = isEmphasized ? Theme.fonts.bodyBold : Theme.fonts.subhead
        }
    }
    
    override var accessibilityLabel: String? {
        set {
            textView.accessibilityLabel = newValue
        }
        get {
            textView.accessibilityLabel
        }
    }
    
    override var accessibilityHint: String? {
        set {
            textView.accessibilityHint = newValue
        }
        get {
            textView.accessibilityHint
        }
    }
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        
        isEmphasized = false
        
        super.init(frame: .zero)
        
        label.isAccessibilityElement = false
        label.text = object[keyPath: path].label
        label.isHidden = (label.text == nil)
        
        textView.accessibilityLabel = label.text
        textView.isEditable = true
        textView.textContainerInset = .topBottom(13) + .leftRight(12)
        textView.backgroundColor = Theme.colors.tertiary
        textView.layer.cornerRadius = 8
        
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        VStack(spacing: 8, label, textView)
            .embed(in: self)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        if let text = object[keyPath: path].value {
            textView.text = text
        }
        
        textView.textChanged { [weak self] in
            self?.object?[keyPath: path].value = $0?.isEmpty == false ? $0 : nil
        }
    }
    
    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .recognized else { return }
        textView.becomeFirstResponder()
    }
    
    @discardableResult
    func emphasized() -> Self {
        isEmphasized = true
        return self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    private(set) var label = UILabel(subhead: nil)
}
