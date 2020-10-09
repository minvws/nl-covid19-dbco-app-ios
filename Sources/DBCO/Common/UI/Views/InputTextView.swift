/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class InputTextView<Object: AnyObject, Field: Editable>: UIView {
    private weak var object: Object?
    
    private let textView = TextView()
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        
        super.init(frame: .zero)
        
        let label = UILabel()
        label.text = Field.label
        
        textView.isEditable = true
        textView.textContainerInset = .topBottom(13) + .leftRight(12)
        textView.backgroundColor = Theme.colors.tertiary
        textView.layer.cornerRadius = 8
        
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        VStack(spacing: 8, label, textView)
            .embed(in: self)
        
        accessibilityLabel = Field.label
        accessibilityElements = [textView]
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        if let text = object[keyPath: path].value {
            textView.text = text
        }
        
        textView.textChanged { [weak self] in
            self?.object?[keyPath: path].value = $0
        }
    }
    
    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .recognized else { return }
        textView.becomeFirstResponder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
