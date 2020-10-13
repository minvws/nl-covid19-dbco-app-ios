/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class ToggleButton: UIButton {
    
    override var isSelected: Bool {
        didSet {
            applySelectedState()
        }
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
        contentEdgeInsets = .topBottom(25.5) + .leftRight(16)
        
        layer.cornerRadius = 8
        
        titleLabel?.font = Theme.fonts.body
        
        tintColor = .white
        backgroundColor = Theme.colors.tertiary
        setTitleColor(.black, for: .normal)
        contentHorizontalAlignment = .left
        
        applySelectedState()
    }
    
    private func applySelectedState() {
        if isSelected {
            layer.borderWidth = 2
            layer.borderColor = Theme.colors.primary.cgColor
            icon.isHighlighted = true
        } else {
            layer.borderWidth = 0
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
        
        if #available(iOS 13.4, *) {
            datePicker.addTarget(self, action: #selector(updateDateValue), for: .editingDidEnd)
            datePicker.preferredDatePickerStyle = .automatic
            datePicker
                .withInsets(.leftRight(4))
                .embed(in: self)
            
            accessibilityElements = [datePicker]
        } else {
            datePicker.addTarget(self, action: #selector(updateDateValue), for: .valueChanged)
            offscreenTextField.delegate = self
            offscreenTextField.inputView = datePicker
            offscreenTextField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
            offscreenTextField.frame = CGRect(x: -2000, y: 0, width: 10, height: 10)
            
            setTitle(Self.dateFormatter.string(from: datePicker.date), for: .normal)
            
            addSubview(offscreenTextField)
            
            addTarget(self, action: #selector(showPicker), for: .touchUpInside)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resetDatePickerBackground()
    }
    
    // MARK: - Private
    @objc private func showPicker() {
        offscreenTextField.becomeFirstResponder()
    }
    
    @objc private func done() {
        offscreenTextField.resignFirstResponder()
    }
    
    @objc private func updateDateValue() {
        resetDatePickerBackground()
        
        date = datePicker.date
        isSelected = true
        sendActions(for: .valueChanged)
        
        if #available(iOS 13.4, *) {
        } else {
            setTitle(Self.dateFormatter.string(from: datePicker.date), for: .normal)
        }
    }
    
    private func resetDatePickerBackground() {
        datePicker.subviews.first?.subviews.first?.backgroundColor = .clear
        
        // Schedule clearing the backgroundColor again on the next runloop.
        // This seems to handle all cases where the UIDatePicker resets its backgroundColor
        DispatchQueue.main.async { [datePicker] in
            datePicker.subviews.first?.subviews.first?.backgroundColor = .clear
        }
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
