/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol InputFieldDelegate: class {
    func promptOptionsForInputField(_ options: [String], selectOption: @escaping (String?) -> Void)
}

/// A styled UITextField subclass that binds to an object's field conforming to [InputFieldEditable](x-source-tag://InputFieldEditable) and automatically updates its value.
/// InputField adjusts its input method based on the properties of the supplied [InputFieldEditable](x-source-tag://InputFieldEditable) field.
///
/// Currently supports the different system keyboards, a date picker (.wheels style) and a general picker wheel.
/// - Tag: InputField
class InputField<Object: AnyObject, Field: InputFieldEditable>: TextField, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private weak var object: Object?
    private let path: WritableKeyPath<Object, Field>
    
    weak var inputFieldDelegate: InputFieldDelegate?
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        self.path = path
        
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isEmphasized: Bool {
        didSet {
            label.font = isEmphasized ? Theme.fonts.bodyBold : Theme.fonts.subhead
        }
    }
    
    private func setup() {
        delegate = self
        
        dropdownIconView.image = UIImage(named: "DropdownIndicator")
        dropdownIconView.contentMode = .right
        dropdownIconView.isUserInteractionEnabled = false
        dropdownIconView.isHidden = true

        validationIconView.image = UIImage(named: "Validation/Invalid")
        validationIconView.highlightedImage = UIImage(named: "Validation/Valid")
        validationIconView.contentMode = .center
        validationIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textWidthLabel.alpha = 0
        
        iconContainerView.addArrangedSubview(HStack(spacing: 5, textWidthLabel, validationIconView).alignment(.center))
        iconContainerView.axis = .vertical
        iconContainerView.alignment = .leading
        iconContainerView.isUserInteractionEnabled = false
        iconContainerView.isHidden = true
        iconContainerView.frame.size.width = 100 // To prevent some constraint errors before layout
        
        addSubview(iconContainerView)
        addSubview(dropdownIconView)
        
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEndOnExit)
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        
        label.text = object?[keyPath: path].label
        label.isAccessibilityElement = false
        
        accessibilityLabel = label.text
        placeholder = object?[keyPath: path].placeholder
        text = object?[keyPath: path].value
        
        configureInputType()
    }
    
    private func configureInputType() {
        inputAccessoryView = nil
        inputView = nil
        
        guard let object = object else { return }

        switch object[keyPath: path].inputType {
        case .text:
            keyboardType = object[keyPath: path].keyboardType
            autocapitalizationType = object[keyPath: path].autocapitalizationType
            textContentType = object[keyPath: path].textContentType
        case .number:
            keyboardType = .numberPad
            inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        case .date(let dateFormatter):
            setupAsDatePicker(with: dateFormatter)
        case .picker(let options):
            setupAsPicker(with: options)
        }
    }
    
    private func setupAsDatePicker(with dateFormatter: DateFormatter) {
        let datePicker = UIDatePicker()
        
        if let text = text, let date = dateFormatter.date(from: text) {
            datePicker.date = date
        } else {
            datePicker.date = DateComponents(calendar: Calendar.current,
                                             timeZone: TimeZone.current,
                                             year: 1980,
                                             month: 1,
                                             day: 1).date ?? Date()
        }
        
        datePicker.datePickerMode = .date
        datePicker.tintColor = .black
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())
        datePicker.addTarget(self, action: #selector(handleDateValueChanged), for: .valueChanged)
        
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        
        self.datePicker = datePicker
        
        inputView = datePicker
        inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        tintColor = .clear
    }
    
    private func setupAsPicker(with options: [InputType.PickerOption]) {
        guard let object = object else { return }
        
        pickerOptions = [("", "")] + options

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        
        let selectedIdentifier = object[keyPath: path].value

        pickerOptions?
            .firstIndex { $0.identifier == selectedIdentifier }
            .map { picker.selectRow($0, inComponent: 0, animated: false) }
        
        text = pickerOptions?.first { $0.identifier == selectedIdentifier }?.value

        inputView = picker
        inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        tintColor = .clear
        optionPicker = picker
        
        dropdownIconView.isHidden = false
        accessibilityTraits = [.button, .staticText]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        iconContainerView.frame = backgroundView.frame.inset(by: .leftRight(12))
        dropdownIconView.frame = backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override var text: String? {
        didSet {
            textWidthLabel.text = text
            updateValidationStateIfNeeded()
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
            updateValidationStateIfNeeded()
        }
    }
    
    @discardableResult
    func delegate(_ delegate: InputFieldDelegate?) -> Self {
        inputFieldDelegate = delegate
        return self
    }
    
    @discardableResult
    func emphasized() -> Self {
        isEmphasized = true
        return self
    }
    
    // MARK: - Private
    
    @objc private func handleEditingDidEnd() {
        
        switch object?[keyPath: path].inputType ?? .text {
        case .picker:
            object?[keyPath: path].value = pickerOptions?[optionPicker!.selectedRow(inComponent: 0)].identifier
        default:
            let trimmedText = text?.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            object?[keyPath: path].value = trimmedText?.isEmpty == false ? trimmedText : nil
        }
        
        updateValidationStateIfNeeded()
    }
    
    @objc private func handleEditingDidBegin() {
        iconContainerView.isHidden = true
        hideWarning()
        hideError()
        currentValidationTask?.cancel()
    }
    
    @objc private func handleDateValueChanged(_ datePicker: UIDatePicker) {
        setDateValueIfNeeded()
    }
    
    @objc private func done() {
        resignFirstResponder()
        setDateValueIfNeeded()
    }
    
    private func setDateValueIfNeeded() {
        guard case .date(let formatter) = object?[keyPath: path].inputType, let datePicker = datePicker else { return }

        object?[keyPath: path].value = formatter.string(from: datePicker.date)
        text = formatter.string(from: datePicker.date)
    }
    
    private func updateValidationStateIfNeeded() {
        guard let validator = object?[keyPath: path].validator else { return }
        currentValidationTask?.cancel()
        
        currentValidationTask = validator.validate(object?[keyPath: path].value) { [weak self] in
            guard let self = self else { return }
            
            switch $0 {
            case .invalid(let error) where error?.isEmpty == false:
                self.showError(error!)
                self.iconContainerView.isHidden = true
            case .invalid:
                self.iconContainerView.isHidden = false
                self.validationIconView.isHighlighted = false
            case .warning(let warning) where warning?.isEmpty == false:
                self.showWarning(warning!)
                self.iconContainerView.isHidden = true
            case .warning:
                self.iconContainerView.isHidden = false
                self.validationIconView.isHighlighted = false
            case .valid:
                self.iconContainerView.isHidden = false
                self.validationIconView.isHighlighted = true
            case .unknown:
                self.iconContainerView.isHidden = true
            }
        }
    }
    
    private var datePicker: UIDatePicker?
    private var optionPicker: UIPickerView?
    private var pickerOptions: [InputType.PickerOption]?
    private var textWidthLabel = UILabel()
    private var validationIconView = UIImageView()
    private var dropdownIconView = UIImageView()
    private lazy var iconContainerView = UIStackView()
    
    private var currentValidationTask: ValidationTask?
    
    // MARK: - Delegate implementations
    
    private var overrideOptionPrompt: Bool = false
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let editable = object?[keyPath: path] else { return true }
        
        switch editable.inputType {
        case .date, .picker:
            UIAccessibility.post(notification: .screenChanged, argument: inputView)
            return true
        default:
            break
        }
        
        guard let delegate = inputFieldDelegate else { return true }
        
        if let options = editable.valueOptions, options.count > 1, text?.isEmpty == true, !overrideOptionPrompt {
            delegate.promptOptionsForInputField(options) { (option) in
                if let option = option {
                    self.text = option
                    self.handleEditingDidEnd()
                } else {
                    self.overrideOptionPrompt = true
                    self.becomeFirstResponder()
                    self.overrideOptionPrompt = false
                }
            }
            return false
        } else {
            return true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText: String
        if let text = text {
            let replacementString = string.replacingOccurrences(of: "\n", with: "") // ignoring newlines like the textfield itself does
            newText = (text as NSString).replacingCharacters(in: range, with: replacementString)
        } else {
            newText = string
        }
        
        // Enforce max length
        guard newText.count <= Constants.maxLength else { return false }
        
        textWidthLabel.text = newText
        
        guard let object = object else { return true }
        
        switch object[keyPath: path].inputType {
        case .date, .picker:
            return false
        default:
            return true
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions?[row].value
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        text = pickerOptions?[row].value
    }
    
}

private struct Constants {
    static let maxLength = 255
}
