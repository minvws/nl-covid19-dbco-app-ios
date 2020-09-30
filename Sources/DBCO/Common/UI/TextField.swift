/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class TextField: UITextField {
    
    enum InputType {
        case text
        case name
        case email
        case options([String])
        case date(DateFormatter)
        case number
    }
    
    typealias ValueHandler = (String?) -> Void
    typealias Validator = (String?) -> Bool
    
    var editingDidEndHandler: ValueHandler?
    var validator: Validator? {
        didSet {
            validateIfNeeded()
        }
    }
    
    var inputType: InputType = .text {
        didSet {
            configureInputType()
        }
    }
    
    override var placeholder: String? {
        didSet {
            label.text = placeholder
        }
    }
    
    init(label: String, text: String? = nil) {
        super.init(frame: .zero)
        setup()
        
        placeholder = label
        self.text = text
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        delegate = self

        validationIconView.image = UIImage(systemName: "exclamationmark.circle.fill")?
            .withTintColor(Theme.colors.warning)
            .withRenderingMode(.alwaysOriginal)
        validationIconView.highlightedImage = UIImage(systemName: "checkmark.circle.fill")?
            .withTintColor(Theme.colors.ok)
            .withRenderingMode(.alwaysOriginal)
        validationIconView.contentMode = .center
        validationIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textWidthLabel.alpha = 0
        
        iconContainerView.addArrangedSubview(UIStackView(horizontal: [textWidthLabel, validationIconView], spacing: 5).alignment(.center))
        iconContainerView.axis = .vertical
        iconContainerView.alignment = .leading
        iconContainerView.isUserInteractionEnabled = false
        iconContainerView.isHidden = true
        
        backgroundView.backgroundColor = Theme.colors.tertiary
        backgroundView.layer.cornerRadius = 8
        backgroundView.isUserInteractionEnabled = false
        
        font = Theme.fonts.body
        
        addSubview(label)
        addSubview(backgroundView)
        addSubview(iconContainerView)
        
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEndOnExit)
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
    }
    
    private func configureInputType() {
        func createDoneToolbar() -> UIToolbar {
            let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
            toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))], animated: false)
            toolBar.barTintColor = .white
            toolBar.sizeToFit()
            return toolBar
        }
        
        inputAccessoryView = nil
        inputView = nil
        
        switch inputType {
        case .text:
            break
        case .number:
            keyboardType = .numberPad
            inputAccessoryView = createDoneToolbar()
            textContentType = .givenName
        case .email:
            keyboardType = .emailAddress
            textContentType = .emailAddress
        case .name:
            keyboardType = .default
            autocapitalizationType = .words
        case .date(let dateFormatter):
            let datePicker = UIDatePicker()
            text.map(dateFormatter.date)?.map { datePicker.date = $0 }
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.addTarget(self, action: #selector(handleDateValueChanged), for: .valueChanged)
            
            inputView = datePicker
            inputAccessoryView = createDoneToolbar()
        case .options(let options):
            pickerOptions = [""] + options
            
            let picker = UIPickerView()
            picker.dataSource = self
            picker.delegate = self
            
            pickerOptions?
                .firstIndex(of: text ?? "")
                .map { picker.selectRow($0, inComponent: 0, animated: false) }
            
            inputView = picker
            inputAccessoryView = createDoneToolbar()
        }
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
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        return CGSize(width: 100, height: labelHeight + Constants.spacing + backgroundHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelSize = label.intrinsicContentSize
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: labelSize.height)
        backgroundView.frame = CGRect(x: 0, y: bounds.height - backgroundHeight, width: bounds.width, height: backgroundHeight)
        iconContainerView.frame = backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override var text: String? {
        didSet {
            textWidthLabel.text = text
            validateIfNeeded()
        }
    }
    
    override var font: UIFont? {
        didSet {
            textWidthLabel.font = font
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
            textWidthLabel.attributedText = attributedText
            validateIfNeeded()
        }
    }
    
    // MARK: - Private
    
    @objc private func handleEditingDidEnd() {
        editingDidEndHandler?(text)
        
        validateIfNeeded()
    }
    
    @objc private func handleEditingDidBegin() {
        editingDidEndHandler?(text)
        
        iconContainerView.isHidden = true
    }
    
    @objc private func handleDateValueChanged(_ datePicker: UIDatePicker) {
        guard case .date(let formatter) = inputType else {
            return
        }
        
        text = formatter.string(from: datePicker.date)
    }
    
    @objc private func done() {
        resignFirstResponder()
    }
    
    private func validateIfNeeded() {
        if let validator = validator, text?.isEmpty == false {
            iconContainerView.isHidden = false
            validationIconView.isHighlighted = validator(text) == true
        } else {
            iconContainerView.isHidden = true
        }
    }
    
    private struct Constants {
        static let spacing: CGFloat = 8
        static let backgroundBaseHeight: CGFloat = 26
    }
    
    private var baseFieldHeight: CGFloat {
        return ceil(font!.lineHeight + 1)
    }
    
    
    private var pickerOptions: [String]?
    private var label = UILabel()
    private var backgroundView = UIView()
    private var textWidthLabel = UILabel()
    private var validationIconView = UIImageView()
    private lazy var iconContainerView = UIStackView()
    
}

extension TextField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = text {
            textWidthLabel.text = (text as NSString).replacingCharacters(in: range, with: string) as String
        }
        
        switch inputType {
        case .date, .options:
            return false
        default:
            return true
        }
    }
    
}

extension TextField: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions?[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        text = pickerOptions?[row]
    }
    
}
