/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

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

        validationIconView.image = UIImage(named: "Validation/Invalid")
        validationIconView.highlightedImage = UIImage(named: "Validation/Valid")
        validationIconView.contentMode = .center
        validationIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textWidthLabel.alpha = 0
        
        iconContainerView.addArrangedSubview(UIStackView(horizontal: [textWidthLabel, validationIconView], spacing: 5).alignment(.center))
        iconContainerView.axis = .vertical
        iconContainerView.alignment = .leading
        iconContainerView.isUserInteractionEnabled = false
        iconContainerView.isHidden = true
        iconContainerView.frame.size.width = 100 // To prevent some constraint errors before layout
        
        addSubview(iconContainerView)
        
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEndOnExit)
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        
        label.text = object?[keyPath: path].label
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
            datePicker.addTarget(self, action: #selector(handleDateValueChanged), for: .valueChanged)
            
            self.datePicker = datePicker
            
            if #available(iOS 14.0, *) {
                addSubview(datePicker)
                datePicker.preferredDatePickerStyle = .automatic
                
                text = nil
                resetDatePickerBackground()
            } else {
                inputView = datePicker
                inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
            }
        case .picker(let options):
            pickerOptions = [("", "")] + options

            let picker = UIPickerView()
            picker.dataSource = self
            picker.delegate = self
            
            let selectedIdentifier = object[keyPath: path].value

            pickerOptions?
                .firstIndex { $0.identifier == selectedIdentifier }
                .map { picker.selectRow($0, inComponent: 0, animated: false) }

            inputView = picker
            inputAccessoryView = UIToolbar.doneToolbar(for: self, selector: #selector(done))
            optionPicker = picker
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        iconContainerView.frame = backgroundView.frame.inset(by: .leftRight(12))
        
        if #available(iOS 14.0, *) {
            datePicker?.frame = backgroundView.frame
            resetDatePickerBackground()
        }
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
            object?[keyPath: path].value = text
        }
        
        updateValidationStateIfNeeded()
    }
    
    @objc private func handleEditingDidBegin() {
        iconContainerView.isHidden = true
    }
    
    @objc private func handleDateValueChanged(_ datePicker: UIDatePicker) {
        guard case .date(let formatter) = object?[keyPath: path].inputType else { return }

        object?[keyPath: path].value = formatter.string(from: datePicker.date)
        resetDatePickerBackground()
        if #available(iOS 14.0, *) {
        } else {
            text = formatter.string(from: datePicker.date)
        }
    }
    
    @objc private func done() {
        resignFirstResponder()
    }
    
    private func updateValidationStateIfNeeded() {
        guard object?[keyPath: path].showValidationState == true else { return }
        
        // TODO: Placeholder implementation
        iconContainerView.isHidden = text?.isEmpty == true
        validationIconView.isHighlighted = true
    }
    
    private func resetDatePickerBackground() {
        guard #available(iOS 14.0, *) else { return }
        
        datePicker?.subviews.first?.subviews.first?.backgroundColor = .clear
        
        // Schedule clearing the backgroundColor again on the next runloop.
        // This seems to handle all cases where the UIDatePicker resets its backgroundColor
        DispatchQueue.main.async { [datePicker] in
            datePicker?.subviews.first?.subviews.first?.backgroundColor = .clear
        }
    }
    
    private var datePicker: UIDatePicker?
    private var optionPicker: UIPickerView?
    private var pickerOptions: [InputType.PickerOption]?
    private var textWidthLabel = UILabel()
    private var validationIconView = UIImageView()
    private lazy var iconContainerView = UIStackView()
    
    // MARK: - Delegate implementations
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard #available(iOS 14.0, *) else { return true }
        guard let object = object else { return true }
        
        switch object[keyPath: path].inputType {
        case .date:
            return false
        default:
            return true
        }
    }
    
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
