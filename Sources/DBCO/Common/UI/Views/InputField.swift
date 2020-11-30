/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A styled UITextField subclass that binds to an object's field conforming to [InputFieldEditable](x-source-tag://InputFieldEditable) and automatically updates its value.
/// InputField adjusts its input method based on the properties of the supplied [InputFieldEditable](x-source-tag://InputFieldEditable) field.
///
/// Currently supports the different system keyboards, a date picker (.wheels style) and a general picker wheel.
/// - Tag: InputField
class InputField<Object: AnyObject, Field: InputFieldEditable>: TextField, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private weak var object: Object?
    private let path: WritableKeyPath<Object, Field>
    
    init(for object: Object, path: WritableKeyPath<Object, Field>) {
        self.object = object
        self.path = path
        
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        label.font = object?[keyPath: path].labelFont
        placeholder = object?[keyPath: path].placeholder
        
        text = object?[keyPath: path].value
        
        configureInputType()
    }
    
    private func configureInputType() {
        inputAccessoryView = nil
        inputView = nil
        
        guard let object = object else {
            return
        }

        switch object[keyPath: path].inputType {
        case .text:
            keyboardType = object[keyPath: path].keyboardType
            autocapitalizationType = object[keyPath: path].autocapitalizationType
            textContentType = object[keyPath: path].textContentType
        case .number:
            keyboardType = .numberPad
            inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
        case .date(let dateFormatter):
            let datePicker = UIDatePicker()
            text.map(dateFormatter.date)?.map { datePicker.date = $0 }
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
        case .picker(let options):
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
            optionPicker = picker
            
            dropdownIconView.isHidden = false
        }
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
        
        switch validator.validate(object?[keyPath: path].value) {
        case .invalid:
            iconContainerView.isHidden = false
            validationIconView.isHighlighted = false
        case .valid:
            iconContainerView.isHidden = false
            validationIconView.isHighlighted = true
        case .unknown:
            iconContainerView.isHidden = true
        }
    }
    
    private var datePicker: UIDatePicker?
    private var optionPicker: UIPickerView?
    private var pickerOptions: [InputType.PickerOption]?
    private var textWidthLabel = UILabel()
    private var validationIconView = UIImageView()
    private var dropdownIconView = UIImageView()
    private lazy var iconContainerView = UIStackView()
    
    // MARK: - Delegate implementations
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = text {
            textWidthLabel.text = (text as NSString).replacingCharacters(in: range, with: string) as String
        }
        
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
