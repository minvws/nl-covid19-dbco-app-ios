/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol InputFieldDelegate: AnyObject {
    func promptOptionsForInputField(_ options: [String], selectOption: @escaping (String?) -> Void)
    func shouldShowValidationResult(_ result: ValidationResult, for sender: AnyObject) -> Bool
}

/// A styled wrapper for [TextField](x-source-tag://TextField) that binds to an object's field conforming to [InputFieldEditable](x-source-tag://InputFieldEditable) and automatically updates its value.
/// InputField adjusts its input method based on the properties of the supplied [InputFieldEditable](x-source-tag://InputFieldEditable) field.
///
/// Currently supports the different system keyboards, a date picker (.wheels style) and a general picker wheel.
/// - Tag: InputField
class InputField<Object: AnyObject, Field: InputFieldEditable>: UIView, LabeledInputView, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private weak var object: Object?
    private let path: WritableKeyPath<Object, Field>
    let label = UILabel(subhead: nil)
    private(set) var textField = TextField()
    
    private var textObserver: Any?
    private var fontObserver: Any?
    private var attributedTextObserver: Any?
    
    weak var inputFieldDelegate: InputFieldDelegate?
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        self.path = path
        
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isEmphasized: Bool = false {
        didSet {
            label.font = isEmphasized ? Theme.fonts.bodyBold : Theme.fonts.subhead
        }
    }
    
    private func setup() {
        VStack(spacing: 8,
               label,
               VStack(spacing: 2,
                      warningContainer,
                      textField,
                      errorContainer))
            .embed(in: self)
        
        warningContainer.isHidden = true
        errorContainer.isHidden = true
        
        setupIcons()
        setupGestureRecognizer()
        setupTextField()
        setupLabels()
        
        configureInputType()
    }
    
    private func setupTextField() {
        textField.delegate = self
        
        textObserver = textField.observe(\.text) { [unowned self] field, _ in self.text = field.text }
        fontObserver = textField.observe(\.font) { [unowned self] field, _ in self.font = field.font }
        
        textField.addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEndOnExit)
        textField.addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        
        textField.placeholder = object?[keyPath: path].placeholder
    }
    
    private func setupLabels() {
        textWidthLabel.font = textField.font
        textWidthLabel.alpha = 0
        
        label.text = object?[keyPath: path].label
        label.isAccessibilityElement = false
        
        accessibilityLabel = label.text
        text = object?[keyPath: path].value
    }
    
    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ sender: Any) {
        textField.becomeFirstResponder()
    }
    
    private func setupIcons() {
        iconContainerView.addArrangedSubview(HStack(spacing: 5, textWidthLabel, validationIconView).alignment(.center))
        
        let iconOverlayView = UIView()
        iconOverlayView.isUserInteractionEnabled = false
        iconOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        iconContainerView.embed(in: iconOverlayView)
        dropdownIconView.embed(in: iconOverlayView)
        
        addSubview(iconOverlayView)
        
        iconOverlayView.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 12).isActive = true
        iconOverlayView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -12).isActive = true
        iconOverlayView.topAnchor.constraint(equalTo: textField.topAnchor).isActive = true
        iconOverlayView.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
    }
    
    private func configureInputType() {
        textField.inputAccessoryView = nil
        textField.inputView = nil
        
        guard let object = object else { return }

        switch object[keyPath: path].inputType {
        case .text:
            textField.keyboardType = object[keyPath: path].keyboardType
            textField.autocapitalizationType = object[keyPath: path].autocapitalizationType
            textField.textContentType = object[keyPath: path].textContentType
        case .number:
            textField.keyboardType = .numberPad
            textField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        case .phoneNumber:
            textField.keyboardType = .phonePad
            textField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
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
        
        textField.inputView = datePicker
        textField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
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

        textField.inputView = picker
        textField.inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        tintColor = .clear
        optionPicker = picker
        
        dropdownIconView.isHidden = false
        accessibilityTraits = [.button, .staticText]
    }
    
    private var text: String? {
        get { textField.text }
        set {
            guard textField.text != newValue else { return }
            textField.text = newValue
            textWidthLabel.text = text
            updateValidationStateIfNeeded()
        }
    }
    
    private var font: UIFont? {
        didSet {
            textWidthLabel.font = font
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
        textField.resignFirstResponder()
        setDateValueIfNeeded()
    }
    
    private func setDateValueIfNeeded() {
        guard case .date(let formatter) = object?[keyPath: path].inputType, let datePicker = datePicker else { return }

        object?[keyPath: path].value = formatter.string(from: datePicker.date)
        text = formatter.string(from: datePicker.date)
    }
    
    func updateValidationStateIfNeeded() {
        guard let validator = object?[keyPath: path].validator else { return }
        currentValidationTask?.cancel()
        
        currentValidationTask = validator.validate(object?[keyPath: path].value) { [weak self] in
            guard let self = self else { return }
            guard self.inputFieldDelegate?.shouldShowValidationResult($0, for: self) == true else { return }
            
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
            case .empty:
                self.showWarning(.contactInformationMissingWarning)
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
    
    private lazy var validationIconView: UIImageView = {
        let iconView = UIImageView(imageName: "Validation/Invalid", highlightedImageName: "Validation/Valid")
        iconView.contentMode = .center
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iconView
    }()
    
    private lazy var dropdownIconView: UIImageView = {
        let iconView = UIImageView(imageName: "DropdownIndicator")
        iconView.contentMode = .right
        iconView.isHidden = true
        return iconView
    }()
    
    private lazy var iconContainerView: UIStackView = {
        let stackView = VStack()
        stackView.alignment = .leading
        stackView.isHidden = true
        return stackView
    }()
    
    private var currentValidationTask: ValidationTask?
    
    // MARK: - Errors and warnings
    func showWarning(_ warning: String) {
        warningContainer.isHidden = false
        warningLabel.text = warning
    }
    
    func hideWarning() {
        warningContainer.isHidden = true
    }
    
    func showError(_ error: String) {
        errorContainer.isHidden = false
        errorLabel.text = error
        
        textField.setBorder(width: 1, color: Theme.colors.warning)
    }
    
    func hideError() {
        errorContainer.isHidden = true
        
        textField.setBorder(width: 0)
    }
    
    private lazy var warningLabel = UILabel(subhead: nil, textColor: Theme.colors.primary)
    private lazy var warningIcon = UIImageView(imageName: "Validation/Warning").asIcon(color: Theme.colors.primary)
    private lazy var warningContainer = HStack(spacing: 4, warningIcon, warningLabel).alignment(.top)
    
    private lazy var errorLabel = UILabel(subhead: nil, textColor: Theme.colors.warning)
    private lazy var errorIcon = UIImageView(imageName: "Validation/Invalid").asIcon(color: Theme.colors.warning)
    private lazy var errorContainer = HStack(spacing: 4, errorIcon, errorLabel).alignment(.top)
    
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
            delegate.promptOptionsForInputField(options) { option in
                if let option = option {
                    self.text = option
                    self.handleEditingDidEnd()
                } else {
                    self.overrideOptionPrompt = true
                    self.textField.becomeFirstResponder()
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
    
    var isEnabled: Bool {
        get { textField.isEnabled }
        set { textField.isEnabled = newValue }
    }
}

private struct Constants {
    static let maxLength = 255
}
