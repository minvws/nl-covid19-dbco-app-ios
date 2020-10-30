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
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        
        super.init(frame: .zero)
        
        if let labelText = object[keyPath: path].label {
            label.text = labelText
        } else {
            label.isHidden = true
        }
        
        textView.isEditable = true
        textView.textContainerInset = .topBottom(13) + .leftRight(12)
        textView.backgroundColor = Theme.colors.tertiary
        textView.layer.cornerRadius = 8
        
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        VStack(spacing: 8, label, textView)
            .embed(in: self)
        
        accessibilityLabel = object[keyPath: path].label
        accessibilityElements = [textView]
        
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    private(set) var label = Label(subhead: nil)
}
