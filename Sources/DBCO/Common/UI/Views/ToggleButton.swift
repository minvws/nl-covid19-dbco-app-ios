/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled UIButton subclass that will toggle between highlighted states when tapped.
/// When toggled it will send out a `.valueChanged` action to interested targets.
/// 
/// # See also:
/// [DateToggleButton](x-source-tag://DateToggleButton),
/// [ToggleGroup](x-source-tag://ToggleGroup)
///
/// - Tag: ToggleButton
class ToggleButton: UIButton {
    
    override var isSelected: Bool {
        didSet { applyState() }
    }
    
    override var isEnabled: Bool {
        didSet { applyState() }
    }
    
    var useHapticFeedback = true
    
    required init(title: String = "", selected: Bool = false) {
        icon = UIImageView(image: UIImage(named: "Toggle/Normal"),
                           highlightedImage: UIImage(named: "Toggle/Selected"))
        
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)

        addTarget(self, action: #selector(touchUpAnimation), for: .touchDragExit)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchCancel)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchUpInside)
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        addTarget(self, action: #selector(touchDownAnimation), for: .touchDown)
        
        icon.tintColor = Theme.colors.primary
        icon.contentMode = .center
        icon.snap(to: .right, of: self, insets: .right(16))
        
        isSelected = selected
        
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    fileprivate func setup() {
        clipsToBounds = true
        contentEdgeInsets = .topBottom(25.5) + .left(16) + .right(32)
        
        layer.cornerRadius = 8
        
        titleLabel?.font = Theme.fonts.body
        titleLabel?.numberOfLines = 2
        
        tintColor = .white
        backgroundColor = Theme.colors.tertiary
        setTitleColor(.black, for: .normal)
        contentHorizontalAlignment = .left
        
        applyState()
    }
    
    private func applyState() {
        switch (isSelected, isEnabled) {
        case (true, true):
            layer.borderWidth = 2
            layer.borderColor = Theme.colors.primary.cgColor
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = true
        case (true, false):
            layer.borderWidth = 2
            layer.borderColor = Theme.colors.disabledBorder.cgColor
            icon.tintColor = Theme.colors.disabledIcon
            icon.isHighlighted = true
        default:
            layer.borderWidth = 0
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = false
        }
    }
    
    @objc private func toggle() {
        isSelected.toggle()
        sendActions(for: .valueChanged)
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
    
    fileprivate let icon: UIImageView
}

/// ToggleButton subclass that displays and manages a date value.
/// When toggled it will show a datepicker to change the date value.
/// For this it creates an offscreen `UITextField` with a `UIDatePicker` as its `inputView`
///
/// # See also:
/// [ToggleButton](x-source-tag://ToggleButton),
/// [ToggleGroup](x-source-tag://ToggleGroup)
///
/// - Tag: DateToggleButton
class DateToggleButton: ToggleButton {
    
    var date: Date?
    
    override var isSelected: Bool {
        didSet {
            if !isSelected {
                offscreenTextField.resignFirstResponder()
            }
        }
    }
    
    override fileprivate func setup() {
        super.setup()
        
        let editLabel = UILabel()
        editLabel.translatesAutoresizingMaskIntoConstraints = false
        editLabel.font = Theme.fonts.body
        editLabel.textColor = Theme.colors.primary
        editLabel.text = .edit
        
        addSubview(editLabel)
        
        editLabel.trailingAnchor.constraint(equalTo: icon.leadingAnchor, constant: -16).isActive = true
        editLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(updateDateValue), for: .editingDidEnd)
        datePicker.tintColor = .black
        datePicker.maximumDate = Date()
        
        if let date = date {
            datePicker.date = date
        } else {
            date = datePicker.date
        }
        
        datePicker.addTarget(self, action: #selector(updateDateValue), for: .valueChanged)
        offscreenTextField.delegate = self
        offscreenTextField.inputView = datePicker
        offscreenTextField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        offscreenTextField.frame = CGRect(x: -2000, y: 0, width: 10, height: 10)
        
        setTitle(Self.dateFormatter.string(from: datePicker.date), for: .normal)
        
        addSubview(offscreenTextField)
        
        addTarget(self, action: #selector(showPicker), for: .touchUpInside)
    }
    
    // MARK: - Private
    @objc private func showPicker() {
        offscreenTextField.becomeFirstResponder()
    }
    
    @objc private func done() {
        offscreenTextField.resignFirstResponder()
    }
    
    @objc private func updateDateValue() {
        date = datePicker.date
        isSelected = true
        sendActions(for: .valueChanged)

        setTitle(Self.dateFormatter.string(from: datePicker.date), for: .normal)
    }
    
    private let datePicker = UIDatePicker()
    private let offscreenTextField = UITextField()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        
        return formatter
    }()
}

extension DateToggleButton: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}
