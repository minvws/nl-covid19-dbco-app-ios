/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class OnsetDatePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate, DatePicking {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter
    }()
    
    var maximumDate: Date? { didSet { setupValues() } }
    var minimumDate: Date? { didSet { setupValues() } }
    
    var date: Date = Date()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        delegate = self
        dataSource = self
        
        setupValues()
        selectRow(numberOfDays - 1, inComponent: 0, animated: false)
    }
    
    private var numberOfDays: Int = 0
    
    private func setupValues() {
        let maximumDate = self.maximumDate ?? Date()
        let minimumDate = self.minimumDate ?? Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        numberOfDays = (Calendar.current.dateComponents([.day], from: minimumDate, to: maximumDate).day ?? 0) + 1
        
        reloadAllComponents()
    }
    
    func setDate(_ date: Date, animated: Bool) {
        let maximumDate = self.maximumDate ?? Date()
        let deltaDays = max(Calendar.current.dateComponents([.day], from: date, to: maximumDate).day ?? 0, 0)
        self.date = date
        
        selectRow(numberOfDays - deltaDays - 1, inComponent: 0, animated: animated)
    }
    
    // MARK: - Datasource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfDays
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let deltaDays = numberOfDays - row - 1
        
        if let date = Calendar.current.date(byAdding: .day, value: -deltaDays, to: self.maximumDate ?? Date()) {
            return dateFormatter.string(from: date)
        }
        
        return nil
    }
    
    // MARK: - Delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let deltaDays = numberOfDays - row - 1
        
        if let date = Calendar.current.date(byAdding: .day, value: -deltaDays, to: self.maximumDate ?? Date()) {
            self.date = date
        }
    }
    
}
